# REVIEW: Better way to do this?
GRADES_INVALIDATION_TIME = 1000 * 60 * 20 # 20 minutes
STUDYUTILS_INVALIDATION_TIME = 1000 * 60 * 20 # 20 minutes
CALENDAR_ITEMS_INVALIDATION_TIME = 1000 * 60 * 10 # 10 minutes

# REVIEW: Currently we're storing the last update time in the root of a user
#         object, this is pretty ugly and gets cluttered really fast.

###*
# A static class that connects to and retrieves data from
# external services (eg. Magister).
#
# @class ExternalSercicesConnector
# @static
###
class @ExternalSercicesConnector
	@externalServices = []

	@pushExternalService: (module) =>
		###*
		# Gets or sets the info in the database.
		#
		# @method storedInfo
		# @param [userId] {String} The ID of the user to get (and modify) the data in the database of. If null the current Meteor.userId() will be used.
		# @param [obj] {Object|null} The object to replace the object stored in the database with. If `null` the currently stored info will be _removed_.
		# @return {Object} The info stored in the database.
		###
		module.storedInfo = (userId, obj) ->
			check userId, Match.Optional String
			check obj, Match.Optional Object

			data = -> Meteor.users.findOne(userId).externalServices?[module.name]
			userId ?= Meteor.userId()
			old = data() ? {}

			unless Meteor.users.findOne(userId).externalServices?
				Meteor.users.update userId, $set: externalServices: {}

			if obj?
				x = {}
				x["externalServices.#{module.name}"] = _.extend old, obj

				Meteor.users.update userId, $set: x

			else if _.isNull obj
				x = {}
				x["externalServices.#{module.name}"] = yes

				Meteor.users.update userId, $unset: x

			data()

		###*
		# Checks if the user for the given `userId` has data for this module.
		# @method hasData
		# @param [userId] {String} The ID of the user to check. If null the current this.userId will be used.
		# @return {Boolean} Whether or not the given `user` has data for the current module.
		###
		module.hasData = (userId = @userId) ->
			check userId, Match.Optional Match.OneOf String, Object
			not _.isEmpty module.storedInfo(userId)

		###*
		# Set/Get active state for the current module for the user of the given `userId`.
		# @method active
		# @param [userId] {String} The ID of the user to check. If null the current this.userId will be used.
		# @param [val] {Boolean} The value to set the active state of this module to.
		# @return {Boolean} Whether or not the current module is active.
		###
		module.active = (userId = @userId, val) ->
			check userId, Match.Optional Match.OneOf String, Object
			check val, Match.Optional Boolean

			storedInfo = module.storedInfo userId

			if val?
				module.storedInfo userId, active: !!val

			module.hasData(userId) and (storedInfo.active ? yes)

		@externalServices.push module

Meteor.methods
	###*
	# Updates the grades in the database for the given `userId` or the user
	# in of current connection, unless the grades were updated shortly before.
	#
	# @method updateGrades
	# @param [userId=this.userId] {String} `userId` overwrites the `this.userId` which is used by default which is used by default.
	# @param [forceUpdate=false] {Boolean} If true the grades will be forced to update, otherwise the grades will only be updated if they weren't updated in the last 20 minutes.
	# @param [async=false] {Boolean} If true the execution of this method will allow other method invocations to run in a different fiber.
	# @return {Error[]} An array containing errors from ExternalServices.
	###
	'updateGrades': (userId, forceUpdate = no, async = no) ->
		@unblock() if async
		check userId, Match.Optional String

		userId ?= @userId
		user = Meteor.users.findOne userId
		errors = []

		return errors if not forceUpdate and user.lastGradeUpdateTime?.getTime() > _.now() - GRADES_INVALIDATION_TIME

		services = _.filter ExternalSercicesConnector.externalServices, (s) -> s.active userId
		for externalService in services
			result = null
			try
				result = externalService.getGrades userId,
					from: null
					to: null
					onlyRecent: no
					onlyEnds: no

			catch e
				# TODO: Error pushing seems broken, if it's fixed remove the log line.
				console.log 'error while fetching grades from service.', e
				errors.push e

			for grade in result ? []
				# Update the grade if we're on the server and if it's changed.
				val = StoredGrades.findOne
					ownerId: userId
					externalId: grade.externalId

				if val? and Meteor.isServer
					delete grade._id
					StoredGrades.update val._id, { $set: grade }, modifier: no
				else
					StoredGrades.insert grade

		Meteor.users.update(userId, $set: lastGradeUpdateTime: new Date) if services.length > 0
		errors

	###*
	# Updates the studyUtils in the database for the given `userId` or the user
	# in of current connection, unless the utils were updated shortly before.
	#
	# @method updateStudyUtils
	# @param [userId=this.userId] {String} `userId` overwrites the `this.userId` which is used by default which is used by default.
	# @param [forceUpdate=false] {Boolean} If true the utils will be forced to update, otherwise the utils will only be updated if they weren't updated in the last 20 minutes.
	# @param [async=false] {Boolean} If true the execution of this method will allow other method invocations to run in a different fiber.
	# @return {Error[]} An array containing errors from ExternalServices.
	###
	'updateStudyUtils': (userId, forceUpdate = no, async = no) ->
		@unblock() if async
		check userId, Match.Optional String

		userId ?= @userId
		user = Meteor.users.findOne userId
		errors = []

		return errors if not forceUpdate and user.lastStudyUtilsUpdateTime?.getTime() > _.now() - STUDYUTILS_INVALIDATION_TIME

		services = _.filter ExternalSercicesConnector.externalServices, (s) -> s.active userId
		for externalService in services
			result = null
			try
				result = externalService.getStudyUtils userId
			catch e
				console.log 'error while fetching studyUtils from service.', e
				errors.push e

			for studyUtil in result ? []
				val = StudyUtils.findOne
					ownerId: userId
					externalInfo: studyUtil.externalInfo

				if val? and Meteor.isServer
					delete studyUtil._id
					StudyUtils.update val._id, { $set: studyUtil }, modifier: no
				else
					StudyUtils.insert studyUtil

		Meteor.users.update(userId, $set: lastStudyUtilsUpdateTime: new Date) if services.length > 0
		errors

	###*
	# Updates the CalendarItems in the database for the given `userId` or the user
	# in of current connection, unless the utils were updated shortly before.
	#
	# @method updateCalendarItems
	# @param [userId=this.userId] {String} `userId` overwrites the `this.userId` which is used by default which is used by default.
	# @param [forceUpdate=false] {Boolean} If true the utils will be forced to update, otherwise the utils will only be updated if they weren't updated in the last 10 minutes.
	# @param [async=false] {Boolean} If true the execution of this method will allow other method invocations to run in a different fiber.
	# @return {Error[]} An array containing errors from ExternalServices.
	###
	'updateCalendarItems': (userId = @userId, forceUpdate = no, async = no) ->
		@unblock() if async
		check userId, String

		user = Meteor.users.findOne userId
		errors = []

		from = user.lastCalendarItemUpdateTime ? new Date().addDays -14
		to = new Date().addDays 7

		return errors if not forceUpdate and user.lastCalendarItemUpdateTime?.getTime() > _.now() - CALENDAR_ITEMS_INVALIDATION_TIME

		services = _.filter ExternalSercicesConnector.externalServices, (s) -> s.active userId
		for externalService in services
			result = null
			try
				result = externalService.getCalendarItems userId, from, to
			catch e
				console.log 'error while fetching calendarItems from service.', e
				errors.push e

			for calendarItem in result ? []
				val = CalendarItems.findOne
					ownerId: userId
					externalId: calendarItem.externalId

				if val? and Meteor.isServer
					delete calendarItem._id
					CalendarItems.update val._id, { $set: calendarItem }, modifier: no
				else
					CalendarItems.insert calendarItem

		Meteor.users.update(userId, $set: lastCalendarItemUpdateTime: new Date) if services.length > 0
		errors

	###*
	# Gets the persons matching the given `query` and `type` for the
	# user with the given `userId`
	#
	# @method getPersons
	# @param query {String}
	# @param [type] {String}
	# @param [userId=this.userId] {String}
	# @return {ExternalPerson[]}
	###
	'getPersons': (query, type = undefined, userId = @userId) ->
		# TODO: Store doneQueries so that we can cache them, example:
		# tho -> fetch persons -> store persons
		# thom -> tho is substring of thom, we can locally filter the results
		#         of 'tho' instead of having to request it from the externalService

		check query, String
		check type, Match.Optional String
		check userId, String

		query = query.toLowerCase()
		result = []

		services = _.filter ExternalSercicesConnector.externalServices, (s) -> s.active userId
		for service in services
			result = result.concat service.getPersons userId, query, type

		result

	###*
	# Returns an array containg info about available services.
	# @method getModuleInfo
	# @param [userId=this.userId] {String} The ID of the user to use for the service info.
	# return {Object[]} An array containg objects that hold the info about all the services.
	###
	'getModuleInfo': (userId = @userId) ->
		check userId, String

		_.map ExternalSercicesConnector.externalServices, (s) ->
			name: s.name
			active: s.active userId
			hasData: s.hasData userId

	'createServiceData': (serviceName, params...) ->
		check serviceName, String

		service = _.find ExternalSercicesConnector.externalServices, (s) -> s.name is serviceName
		if service?
			res = service.createData params..., @userId
			if res? and not res # login credentials wrong.
				throw new Meteor.Error 'forbidden', 'Login credentials incorrect.'
		else
			throw new Meteor.Error 'notfound', "No module with the name '#{serviceName}' found."
		undefined

Meteor.publish 'externalCalendarItems', (from, to) ->
	from ?= new Date().addDays -7
	to ?= new Date().addDays 7

	handle = Helpers.interval (=>
		Meteor.call 'updateCalendarItems', @userId, no, yes
	), 1000 * 60 * 20 # 20 minutes

	@onStop ->
		Meteor.clearInterval handle

	CalendarItems.find
		startDate: $gte: new Date().addDays -7
		endDate: $lte: new Date().addDays 7

#Meteor.publish "externalPersons", (query) ->
#	#var words = query.toLowerCase().split(" ");
#	#var persons = _.filter(allPersons, function (p) {
#	#	return _.any(words, function (word) {
#	#		return p.firstName.toLowerCase().indexOf(word) > -1 || p.lastName.toLowerCase().indexOf(word) > -1;
#	#	});
#	#});
#
#	words = query.toLowerCase().split " "
#	persons = Meteor.users.find(
#		"profile.firstName": 
#	).fetch()
#
#	services = _.filter @externalServices, (s) -> s.hasData user
#	
#	for service.getPersons

# Lets push those bindings
ExternalSercicesConnector.pushExternalService MagisterBinding
