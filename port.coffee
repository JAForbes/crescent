###
	Author: James Forbes
	Date: 20140510
	Copyright 2014 
	All Rights Reserverd
###
module.exports = ->

	_ = require 'underscore'
	database = require './db/data.json'
	fs = require 'fs'
	###
		Search for a matching username/password
		Allow/deny access to the database at their credential level.
	###

	login = (username,password) ->
		user_id = pivotSearch '_users','name', username
		user = database.data[user_id]
		
		if username and password and user?.password is password
			talk user_id	
		else
			'Invalid username or password'	

	###
		The top level of transactions after logging in.
		The user is baked in via a closure.
	###

	talk = (user) ->
		(query) ->
			if _(query).isString()
				if database.tables[query]
					table query,user
				else if query not in ['..','.']
					createTable query,user
			else
				_(database.tables).keys()

	###
		Return the first id of the record that 
		matches an attribute name and value within a table.

		Useful for logging in.
	###

	pivotSearch = (tablename,attributeName,value) ->
		_id = null
		_(database.data)
			.chain()
			.pick(database.tables[tablename])
			.every (row,id) ->
				if row[attributeName] is value
					_id = id
				row[attributeName] isnt value
			.value()
		_id

	table = (tablename,user) ->
		(query) ->
			if _(query).isUndefined() 
				tableAccess(tablename,user)
			else if _(query).isNumber()
				row tablename,query,user 
			else if _(query).isFunction()
				apply tablename,user,query
			else if _(query).isObject()
				createRow tablename,query,user
			else if query is null
				deleteTable tablename,query,user
			else if query is '.'
				table tablename,user
			else if query is '..'
				talk user
			else
				table tablename,user

	createTable = (tablename,user) ->
		console.log 'createTable',tablename,user
		if database.data[user].role is 'admin'
			database.tables[tablename] = []
			save(table,[tablename,user])
		else 
			'User does not have table creation privilege.'

	tableAccess = (tablename,user) ->
		response = {}
		result = _(database.data).pick database.tables[tablename]
		role = database.data[user].role

		if role is 'admin'
			response = result
		else if role == 'user'
			_(result).each (row,id) ->
				if user in row.access
					response[id] = row
		response

	row = (tablename,id,user) ->
		(query) ->
			access = rowAccess id,user
			if _(query).isUndefined()
				access
			else if _(access).isObject()
				if _(query).isObject()
					editRow tablename,id,user,query
				else if query is null
					deleteRow tablename,id,user,query
				else
					access
			else
				table tablename,user

	rowAccess = (row,user) ->
		result = database.data[row]
		role = database.data[user].role
		allowed = role is 'admin' or role is 'user' and user in result.access

		if allowed
			result
		else
			'Invalid access.'

	apply = (tablename,user,apply) ->
		applyed = {}
		changed = false

		_(tableAccess(tablename,user)).each (row,id) ->
			unless changed
				before = _.clone(row)

			if apply.call null,row,id 
				applyed[id] = row

			unless changed
				changed = not _.isEqual(row,before)
		done = ->
			(query) ->
				if _(query).isUndefined()
					applyed
				else
					table tablename,user query
		if changed 
			save done
		else
			done

	sequentialID = () ->
		database.sequential+=1

	save = (done,args) ->
		_.defer( ->
			fs.writeFile('./db/data.json',JSON.stringify(database,null,2), "utf8");
		)
		done.apply(null,args);

	createRow = (tablename,row,user) ->
		if tablename.charAt(0) isnt '_'
			id = sequentialID()
			database.tables[tablename].push(id)
			database.data[id] = row
			save table,[tablename,user]
		else
			'Cannot modify restricted tables'

	editRow = (tablename,row,user,query) ->
		_(database.data[row]).extend(query)
		save table,[tablename,user]

	deleteRow = (tablename,row,user,query) ->
		delete database.data[row]
		save table,[tablename,user]


	deleteTable = (tablename,query,user) ->
		_(database.tables[tablename]).each (row) ->
			delete database.data[row]
		delete database.tables[tablename]
		save table,[tablename,user]

	#Entry point
	return -> login.apply this, arguments