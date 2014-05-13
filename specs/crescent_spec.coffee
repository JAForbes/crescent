db = require('../port')()
_ = require('underscore')

#disable logging
specs = 
	login:
		'should deny access for invalid passwords': ->
			talk = db('admin','invalid')
			talk is 'Invalid username or password'

		'should allow access for valid credentials': ->
			talk = db('admin','password')
			type(talk()) is 'Array'

	'an admin':
		'can create tables': ->
			testTable = 'new table'
			#create the new table
			tableList = db('admin','password')(testTable)('..')()
			#destroy the new table
			restoredList = db('admin','password')(testTable)(null)

			testTable in tableList and testTable not in restoredList


		'can destroy tables': ->
			testTable = 'new table'
			#create the new table
			tableList = db('admin','password')(testTable)('..')()
			#destroy the new table
			restoredList = db('admin','password')(testTable)(null)()

			testTable in tableList and testTable not in restoredList

		'can create restricted tables': ->
			restrictedTable = '_restricted'

			talk = db('admin','password')
			
			tableList = talk(restrictedTable)('..')()

			restoredList = talk(restrictedTable)(null)()

			restrictedTable in tableList and restrictedTable not in restoredList

		'can destroy restricted tables': ->
			restrictedTable = '_restricted'

			talk = db('admin','password')
			
			tableList = talk(restrictedTable)('..')()

			restoredList = talk(restrictedTable)(null)()

			restrictedTable in tableList and restrictedTable not in restoredList

		'can create and modify restricted records': ->
			restrictedTable = '_restricted'

			talk = db('admin','password')
			
			#create the table and a record
			contents = talk(restrictedTable)({a: 'created'})('.')()


			#get id of new record
			id = _(contents).chain().keys().last().value()

			#add a new field to the record
			talk(restrictedTable)(id)({ b: 'modified' })()


			createdAndModified = _(talk(restrictedTable)(id)()).isEqual({a: 'created', b: 'modified'})
			deleted = restrictedTable not in talk(restrictedTable)(null)()

			createdAndModified and deleted

	'A user':
		'cannot create tables': ->
			testTable = 'new table'
			#create the new table
			errorMessage = db('basic','password')(testTable)

			type(errorMessage) is 'String'

		'cannot destroy tables': ->
			testTable = 'new table'
			db('admin','password')(testTable)()
			error =  db('basic','password')(testTable)(null)
			restoredList = db('admin','password')(testTable)(null)()

			type(error) is 'String' and testTable not in restoredList

type = (actual) ->
		({})
			.toString.call(actual)#[Object String]
			.slice(8,-1)#String

specRunner = (specs) ->

	passed = []
	failed = []

	_(specs).each (expectations,spec) ->
		_(expectations).each (expectation,title) ->
					
				if do expectation
					passed.push [spec + ' ' + title]
				else
					failed.push [spec + ' ' + title]

	nPassed = passed.length 
	nTests = nPassed + failed.length
	console.log "Passed #{nPassed} out of #{nTests}"
	failed and _(failed).each (failure) ->	console.log "FAIL: #{failure}"

specRunner specs
