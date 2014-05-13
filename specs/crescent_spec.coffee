db = require('../port')()
_ = require('underscore')

#disable logging
test = 
	log: console.log

console.log = ->

type = (actual) ->
	({})
		.toString.call(actual)#[Object String]
		.slice(8,-1)#String

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
			restoredList = db('admin','password')(testTable)(null)('..')()

			testTable in tableList and testTable not in restoredList

	

do ->

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
	test.log "Passed #{nPassed} out of #{nTests}"
	failed and _(failed).each (failure) ->	test.log "FAIL: #{failure}"