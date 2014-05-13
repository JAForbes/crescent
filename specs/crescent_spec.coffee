db = require('../port')()
admin = db('admin','password')
basic = db('basic','password')

_ = require('underscore')



#disable logging
specs = 
	login:
		'should deny access for invalid passwords': ->
			talk = db('admin','invalid')
			talk is 'Invalid username or password'

		'should allow access for valid credentials': ->
			type(admin()) is 'Array'

	'an admin':
		'can create tables': ->
			testTable = 'new table'
			#create the new table
			tableList = admin(testTable)('..')()
			#destroy the new table
			restoredList = admin(testTable)(null)

			testTable in tableList and testTable not in restoredList


		'can destroy tables': ->
			testTable = 'new table'
			#create the new table
			tableList = admin(testTable)('..')()
			#destroy the new table
			restoredList = admin(testTable)(null)()

			testTable in tableList and testTable not in restoredList

		'can create restricted tables': ->
			restrictedTable = '_restricted'

			talk = admin
			
			tableList = talk(restrictedTable)('..')()

			restoredList = talk(restrictedTable)(null)()

			restrictedTable in tableList and restrictedTable not in restoredList

		'can destroy restricted tables': ->
			restrictedTable = '_restricted'

			talk = admin
			
			tableList = talk(restrictedTable)('..')()

			restoredList = talk(restrictedTable)(null)()

			created = restrictedTable in tableList
			deleted = restrictedTable not in restoredList
			
			created and deleted

		'can create and modify restricted records': ->
			restrictedTable = '_restricted'

			talk = admin
			
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
			errorMessage = basic(testTable)

			type(errorMessage) is 'String'

		'cannot destroy tables': ->
			testTable = 'new table'
			admin(testTable)()
			errorOccured =  type(basic(testTable)(null)) is 'String'
			deleted = testTable not in admin(testTable)(null)()
			
			errorOccured and deleted

		'cannot view records without access': ->
			testTable = 'new table'
			
			admin(testTable)({no: 'access'})()

			couldNotSee = _(basic(testTable)()).isEmpty()

			deleted = testTable not in admin(testTable)(null)()

			couldNotSee and deleted

		'can view records if they have access': ->
			testTable = 'new table'
			basicId = 2

			admin(testTable)({can: 'access', access: [basicId] })()

			couldSee = not _.isEmpty(basic(testTable)())


			deleted = testTable not in admin(testTable)(null)()
			couldSee and deleted

		'cannot modify restricted records, even if the id is known': ->
			testTable = 'new table'
			
			result = admin(testTable)({cannot: 'access', modified: false})()

			result_id = _(result).keys()[0]
			
			couldNotSee = type(basic(testTable)(result_id)()) is 'String'
			couldNotModify = type(basic(testTable)(result_id)({modified: true})) is 'String'
			couldNotDelete = type(basic(testTable)(result_id)(null)) is 'String'

			beforeAndAfterSame = _.isEqual(result,admin(testTable)())

			deleted = testTable not in admin(testTable)(null)()

			beforeAndAfterSame and 
				couldNotSee and 
				couldNotModify and 
				couldNotDelete and 
				deleted

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
	_(passed).each (success) ->	console.log "SUCCESS: #{success}"
	_(failed).each (failure) ->	console.log "FAIL: #{failure}"

specRunner specs