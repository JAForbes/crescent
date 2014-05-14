/*
	Author: James Forbes
	Date: 20140510
	Copyright 2014 
	All Rights Reserverd
 */
var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

module.exports = function() {
  var apply, createRow, createTable, database, deleteRow, deleteTable, editRow, fs, login, pivotSearch, row, rowAccess, save, sequentialID, table, tableAccess, talk, _;
  _ = require('underscore');
  database = require('../../db/data.json');
  fs = require('fs');

  /*
  		Search for a matching username/password
  		Allow/deny access to the database at their credential level.
   */
  login = function(username, password) {
    var user, user_id;
    user_id = pivotSearch('_users', 'name', username);
    user = database.data[user_id];
    if (username && password && (user != null ? user.password : void 0) === password) {
      return talk(user_id * 1);
    } else {
      return 'Invalid username or password';
    }
  };

  /*
  		The top level of transactions after logging in.
  		The user is baked in via a closure.
   */
  talk = function(user) {
    return function(query) {
      if (_(query).isString()) {
        if (database.tables[query]) {
          return table(query, user);
        } else if (query !== '..' && query !== '.') {
          return createTable(query, user);
        }
      } else {
        return _(database.tables).keys();
      }
    };
  };

  /*
  		Return the first id of the record that 
  		matches an attribute name and value within a table.
  
  		Useful for logging in.
   */
  pivotSearch = function(tablename, attributeName, value) {
    var _id;
    _id = null;
    _(database.data).chain().pick(database.tables[tablename]).every(function(row, id) {
      if (row[attributeName] === value) {
        _id = id;
      }
      return row[attributeName] !== value;
    }).value();
    return _id;
  };
  table = function(tablename, user) {
    return function(query) {
      if (_(query).isUndefined()) {
        return tableAccess(tablename, user);
      } else if (_(query).isNumber() || _(query).isString() && /\d/.test(query)) {
        return row(tablename, query, user);
      } else if (_(query).isFunction()) {
        return apply(tablename, user, query);
      } else if (_(query).isObject()) {
        return createRow(tablename, query, user);
      } else if (query === null) {
        return deleteTable(tablename, query, user);
      } else if (query === '.') {
        return table(tablename, user);
      } else if (query === '..') {
        return talk(user);
      } else {
        return table(tablename, user);
      }
    };
  };
  createTable = function(tablename, user) {
    if (database.data[user].role === 'admin') {
      database.tables[tablename] = [];
      return save(table, [tablename, user]);
    } else {
      return 'User does not have table creation privilege.';
    }
  };
  tableAccess = function(tablename, user) {
    var response, result, role;
    response = {};
    result = _(database.data).pick(database.tables[tablename]);
    role = database.data[user].role;
    if (role === 'admin') {
      response = result;
    } else if (role === 'user') {
      _(result).each(function(row, id) {
        if (row.access && __indexOf.call(row.access, user) >= 0) {
          return response[id] = row;
        }
      });
    }
    return response;
  };
  row = function(tablename, id, user) {
    return function(query) {
      var access;
      access = rowAccess(id, user);
      if (_(query).isUndefined()) {
        return access;
      } else if (_(access).isObject()) {
        if (_(query).isObject()) {
          return editRow(tablename, id, user, query);
        } else if (query === null) {
          return deleteRow(tablename, id, user, query);
        } else {
          return access;
        }
      } else {
        return access;
      }
    };
  };
  rowAccess = function(row, user) {
    var allowed, result, role;
    result = database.data[row];
    role = database.data[user].role;
    allowed = role === 'admin' || role === 'user' && result.access && __indexOf.call(result.access, user) >= 0;
    if (allowed) {
      return result;
    } else {
      return 'Invalid access.';
    }
  };
  apply = function(tablename, user, apply) {
    var applyed, changed, done;
    applyed = {};
    changed = false;
    _(tableAccess(tablename, user)).each(function(record, id) {
      var before;
      if (!changed) {
        before = _.clone(record);
      }
      if (apply.call(null, record, id)) {
        applyed[id] = record;
      }
      if (!changed) {
        return changed = !_.isEqual(record, before);
      }
    });
    done = function() {
      return function(query) {
        if (_(query).isUndefined()) {
          return applyed;
        } else {
          return table(tablename, user(query));
        }
      };
    };
    if (changed) {
      return save(done);
    } else {
      return done();
    }
  };
  sequentialID = function() {
    return database.sequential += 1;
  };
  save = function(done, args) {
    _.defer(function() {
      return fs.writeFile('./db/data.json', JSON.stringify(database, null, 2), "utf8", function() {});
    });
    return done.apply(null, args);
  };
  createRow = function(tablename, row, user) {
    var id;
    if (database.data[user].role === 'admin' || tablename.charAt(0) !== '_') {
      id = sequentialID();
      database.tables[tablename].push(id);
      database.data[id] = row;
      return save(table, [tablename, user]);
    } else {
      return 'Cannot modify restricted tables';
    }
  };
  editRow = function(tablename, row, user, query) {
    _(database.data[row]).extend(query);
    return save(table, [tablename, user]);
  };
  deleteRow = function(tablename, row, user, query) {
    delete database.data[row];
    return save(table, [tablename, user]);
  };
  deleteTable = function(tablename, query, user) {
    if (database.data[user].role === 'admin') {
      _(database.tables[tablename]).each(function(row) {
        return delete database.data[row];
      });
      delete database.tables[tablename];
      return save(talk, [user]);
    } else {
      return 'A user cannot delete a table.';
    }
  };
  return function() {
    return login.apply(this, arguments);
  };
};
