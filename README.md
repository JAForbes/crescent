crescent
========

A convenient API for a simple JSON store.  Includes basic security roles.  Useful for setting up persistence for simple, non-concurrent apps.

Installation
------------

`npm install JAForbes/crescent`

Usage
-----

_Logging in:_

`var db = require('crescent')('admin','password')`

_List tables_

`db()`

_List records of table_

`db(tablename)()`

_Create record_

`db(tablename)({ foo: 'bar' })()`

_Modify record_

`db(tablename)(record_id)({ foo: 'baz' })()`

_Delete record_

`db(tablename)(record_id)(null)()`

_Delete table_

`db(tablename)(null)`

_Create table_

`db(tablename)({first: 'record', of: 'new table'})()`

_Navigation_

Return to current table from record with `.`:

`db(tablename)(record_id)('.')()`

Return to table list with `..`:

`db(tablename)('..')()`

_Roles and Access_

There are two roles, `'admin'` and `'user'`.

Admins can modify restricted tables and create tables.

Users can create records in existing tables.  Users can also modify records they have access too.

Records have an array `access`.

The `access` array contains the ids of users that are allowed to modify that record.

_Restricted tables_

Tables that begin with an underscore are restricted.  Only an admin can delete an underscored table.

However non admin users can modify records if that record contains an `access` array contain that users id.

_Advanced Querying using functions_

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