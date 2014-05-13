/*
	Author: James Forbes
	Date: 20140510
	Copyright 2014 
	All Rights Reserverd
*/
module.exports = (function(){



	var database = require('./db/data.json');
	var _ = require('underscore');
	function rowAccess(row,user){
		var result = database.data[row];
		var role = database.data[user].role;
		var allowed = role =='admin' || role == 'user' && _(result.access).contains(user);
		if( allowed ){
			return result;
		} else {
			return 'Invalid access.'
		}
	}

	function tableAccess(tablename,user){
		var response = {};
		var result = _(database.data).pick(database.tables[tablename]);
		var role = database.data[user].role;
		if(role == 'admin'){
			return result;
		} else if( role == 'user') {
			_(result).each(function(row,id){
				if( _(row.access).contains(user) ){
					response[id] = row;
				}
			})	
		}
		return response;
	}

	function sequentialID(){
		return database.sequential+=1;
	}

	function createTable(tablename,user){
		if(database.data[user].role == 'admin'){
			database.tables[tablename] = [];
			return save(table,[tablename,user]);
		}
		return 'User does not have table creation privilege.'
	}

	function save(callback,args){
		fs.writeFile('./db/data.json',JSON.stringify(database,null,2), "utf8", function(){
		});
		return callback.apply(null,args);
	}

	function createRow(tablename,row,user){
		if(tablename.charAt(0) != '_'){
			var id = sequentialID();
			database.tables[tablename].push(id)
			database.data[id] = row;
			return save(table,[tablename,user])
		} else {
			return 'Cannot modify restricted tables.'
		}
	}

	function editRow(tablename,row,user,query){
		_(database.data[row]).extend(query)
		return save(table,[tablename,user]);
	}

	function deleteRow(tablename,row,user,query){
		delete database.data[row];
		return save(table,[tablename,user]);
	}

	function row(tablename,id,user){
		return function(query){
			if ( _(query).isUndefined() ){
				return rowAccess(id,user);
			} else if (_(query).isObject() ) {
				var access = rowAccess(id,user);
				if( _(access).isObject() ){
					return editRow(tablename,id,user,query)
				} else {
					return access;
				}
			} else if (query === null){
				var access = rowAccess(id,user);
				if( _(access).isObject() ){
					return deleteRow(tablename,id,user,query)
				} else {
					return access;
				}
			}
			return table(tablename,user)
		}
	}

	function apply(tablename,user,apply){
		var applyed = {}
		var changed = false;
		_(tableAccess(tablename,user)).each(function(row,id){
			if(!changed){
				var before = _.clone(row);
			}

			if(apply.call(null,row,id)){
				applyed[id] = row;
			}

			if(!changed){
				changed = !_.isEqual(row,before);
			}

		});
		function done(){
			return function(query){
				if(_(query).isUndefined() ){
					return applyed;
				}
				return table(tablename,user)(query);
			}
		}

		if(changed){
			return save(done)
		} else {
			return done();
		}
	}

	function findTableByID(id){
		var result;
		_(database.tables).every(function(ids,table,list){
		  if(_(ids).contains(id)){
		    result = table;

		  }
		  return !result;
		})
		return result;
	}

	function deleteTable(tablename,query,user){
		_(database.tables[tablename]).each(function(row){
			delete database.data[row];
		})
		delete database.tables[tablename];
		return save(table,[tablename,user]);
	}

	function table(tablename,user){
		return function(query){
			if(_(query).isUndefined()){
				return tableAccess(tablename,user)
			} else if(_(query).isNumber() ){
				return row(tablename,query,user)
			} else if(_(query).isFunction() ){
				return apply(tablename,user,query);
			} else if( _(query).isObject()) {
				return createRow(tablename,query,user)
			} else if( query === null) {
				return deleteTable(tablename,query,user)
			} else if( query == '.'){
				return table(tablename,user)
			} else if (query == '..'){
				return talk(user);
			}
			return table(tablename,user)
		}
	}

	function talk(user){
		return function(tablename){

			if(_(tablename).isString()){
				if(database.tables[tablename]){
					return table(tablename,user);
				} else if (!_(['..','.']).contains(tablename)){
					return createTable(tablename,user);
				}
			} else if(_(tablename).isNumber()){
				var id = tablename;
				var tablename = findTableByID(id);
				return row(tablename,id,user)
			}
			return _(database.tables).keys();
		}
	}

	function pivotSearch(tablename,attributeName,value){
		var _id;
		_(database.data)
			.chain()
			.pick(database.tables[tablename])
			.every(function(row,id){
				if(row[attributeName] == value){
					_id = id;
				}
				return row[attributeName] != value;
			})
			.value()
		return _id;
	}

	function login(username,password){
		var user_id = pivotSearch('_users','name',username);
		var error;
		if(user_id){
			var user = database.data[user_id];
			if(user.password == password){
				response = talk(user_id)
			} else {
				error = 'Invalid password.'
			}
		} else {
			error = 'Invalid username.'
		}
		if(error) {
			return error;
		}
		return response;
	}
	return function(){
		return login.apply(this,arguments)
	}

})();