crescent
========

A convenient API for a simple JSON store.  Includes basic security roles.  Useful for setting up persistence for simple, non-concurrent apps.

This is an early alpha build v0.00.  Do not use this in production.

Installation
------------

`npm install JAForbes/crescent`

Quick Start
-----------

```javascript
var db = require('crescent')

db('admin','password') //login

//navigate into the users table
('_users') 

//create a new user
({ 
      "name": "james",
      "password": "secret",
      "role": "user"
})

//navigate back to the tables list
('..')

//create a table called messages and navigate back up to root
('messages')('..')

//delete messages table
('messages')(null) 

//set all users named james to admin
('_users')(function(row,id){
	if(row.name == 'james') row.role = 'admin';
})()

```

Tests
-----

To run the tests for crescent enter the following into your terminal.

`npm test`


Usage
-----

__Logging in:__

`var db = require('crescent')('admin','password')`

__List tables__

`db()`

__List records of table__

`db(tablename)()`

__Create record__

`db(tablename)({ foo: 'bar' })()`

__Modify record__

`db(tablename)(record_id)({ foo: 'baz' })()`

__Delete record__

`db(tablename)(record_id)(null)()`

__Delete table__

`db(tablename)(null)`

__Create table__

`db(tablename)({first: 'record', of: 'new table'})()`

__Navigation__

Return to current table from record with `.`:

`db(tablename)(record_id)('.')()`

Return to table list with `..`:

`db(tablename)('..')()`

__Roles and Access__

There are two roles, `'admin'` and `'user'`.

Admins can modify restricted tables and create tables.

Users can create records in existing tables.  Users can also modify records they have access too.

Records have an array called `access`.

The `access` array contains the ids of users that are allowed to modify that record.

Admins automatically have access.

__Restricted tables__

Tables that begin with an underscore are restricted.  Only an admin can delete an underscored table.

However non admin users can modify records if that record contains an `access` array contain that users id.

__Advanced Querying using functions__

The following returns a hash of records that match the critera.

```javascript

//Equivalent to SELECT * FROM <tablename> WHERE name = 'james'
db(tablename)(function(record,id){
	return record.name == 'james'
})()

```

You can also modify data in the loop, and changes are automatically saved.

```javascript

db(tablename)(function(record,id){
	return record.copyright = new Date().getFullYear()
})()

```