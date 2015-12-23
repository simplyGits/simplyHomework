ExternalServiceErrors = new Meteor.Collection 'externalServiceErrors'

# REVIEW: Better way to do this?
GRADES_INVALIDATION_TIME         = 1000 * 60 * 20 # 20 minutes
STUDYUTILS_INVALIDATION_TIME     = 1000 * 60 * 20 # 20 minutes
CALENDAR_ITEMS_INVALIDATION_TIME = 1000 * 60 * 10 # 10 minutes

# REVIEW: Currently we're storing the last update time in the root of a user
#         object, this is pretty ugly and gets cluttered really fast.

markUserEvent = (userId, name) ->
	check userId, String
	check name, String
	Meteor.users.update userId, $set: "events.#{name}": new Date

###*
# A static class that connects to and retrieves data from
# external services (eg. Magister).
#
# @class ExternalServicesConnector
# @static
###
class ExternalServicesConnector
	@externalServices: []

	@pushExternalService: (module) =>
		###*
		# Gets or sets the info in the database.
		#
		# @method storedInfo
		# @param [userId=Meteor.userId()] {String} The ID of the user to get (and modify) the data in the database of. If null the current Meteor.userId() will be used.
		# @param [obj] {Object|null} The object to replace the object stored in the database with. If `null` the currently stored info will be _removed_.
		# @return {Object} The info stored in the database.
		###
		module.storedInfo = (userId = Meteor.userId(), obj) ->
			check userId, Match.Optional String
			check obj, Match.Optional Match.OneOf Object, null

			data = ->
				Meteor.users.findOne(
					userId
					fields: externalServices: 1
				).externalServices[module.name]
			old = data() ? {}

			if obj?
				Meteor.users.update userId,
					$set: "externalServices.#{module.name}": _.extend old, obj

			else if _.isNull obj
				Meteor.users.update userId,
					$unset: "externalServices.#{module.name}": yes

			data()

		###*
		# Checks if the user for the given `userId` has data for this module.
		# @method hasData
		# @param [userId] {String} The ID of the user to check. If `undefined` the current this.userId will be used.
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

			module.hasData(userId) and (storedInfo?.active ? yes)

		###
		CalendarItems.find(
			fetchedBy: module.name
		).observe
			changed: module.calendarItemChanged
		###

		@externalServices.push module

# Just a shortcut.
Services = ExternalServicesConnector.externalServices

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
	'updateGrades': (userId = @userId, forceUpdate = no, async = no) ->
		check userId, String
		check forceUpdate, Boolean
		check async, Boolean

		user = Meteor.users.findOne userId
		gradeUpdateTime = user.events.gradeUpdate?.getTime()
		errors = []

		# return empty array when we don't have to update anything (using `errors`
		# so that we don't have to create a new array, micro-optimisations FTW).
		if not forceUpdate and
		gradeUpdateTime? and gradeUpdateTime > _.now() - GRADES_INVALIDATION_TIME
			return errors

		services = _.filter Services, (s) -> s.getGrades? and s.active userId
		markUserEvent userId, 'gradeUpdate' if services.length > 0

		@unblock() if async

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
				handleServiceError externalService.name, userId, e
				errors.push e
				continue

			for grade in result ? []
				# Update the grade if we're on the server and if it's changed.
				continue unless grade?
				val = Grades.findOne
					ownerId: userId
					externalId: grade.externalId

				if val? and Meteor.isServer
					delete grade._id
					Grades.update val._id, grade, modifier: no
				else
					Grades.insert grade

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
	'updateStudyUtils': (userId = @userId, forceUpdate = no, async = no) ->
		check userId, String
		check forceUpdate, Boolean
		check async, Boolean

		user = Meteor.users.findOne userId
		studyUtilsUpdateTime = user.events.studyUtilsUpdate?.getTime()
		errors = []

		if not forceUpdate and studyUtilsUpdateTime? and
		studyUtilsUpdate > _.now() - STUDYUTILS_INVALIDATION_TIME
			return errors

		services = _.filter Services, (s) -> s.getStudyUtil? and s.active userId
		markUserEvent userId, 'studyUtilsUpdate' if services.length > 0

		@unblock() if async

		for externalService in services
			result = null
			try
				result = externalService.getStudyUtils userId
			catch e
				console.log 'error while fetching studyUtils from service.', e
				handleServiceError externalService.name, userId, e
				errors.push e
				continue

			for studyUtil in result ? []
				val = StudyUtils.findOne
					ownerId: userId
					externalInfo: studyUtil.externalInfo

				if val? and Meteor.isServer
					delete studyUtil._id
					StudyUtils.update val._id, { $set: studyUtil }, modifier: no
				else
					StudyUtils.insert studyUtil

		errors

	# TODO: think out some throtthling for this.
	###*
	# Updates the CalendarItems in the database for the given `userId` or the user
	# in of current connection, unless the utils were updated shortly before.
	#
	# @method updateCalendarItems
	# @param [userId=this.userId] {String} `userId` overwrites the `this.userId` which is used by default which is used by default.
	# @param [async=false] {Boolean} If true the execution of this method will allow other method invocations to run in a different fiber.
	# @param [from] {Date} The date from which to get the calendarItems from.
	# @param [to] {Date} The date till which to get the calendarItems of.
	# @return {Error[]} An array containing errors from ExternalServices.
	###
	'updateCalendarItems': (userId = @userId, async = no, from, to) ->
		check userId, String
		check async, Boolean
		check from, Date
		check to, Date

		user = Meteor.users.findOne userId
		calendarItemsUpdate = undefined#user.events.calendarItemsUpdate
		errors = []

		from ?= calendarItemsUpdate ? new Date().addDays -14
		if not calendarItemsUpdate? and from > new Date().addDays -14
			from = new Date().addDays -14

		to ?= new Date().addDays 7
		to = new Date().addDays(7) if to < new Date().addDays(7)

		services = _.filter Services, (s) -> s.getCalendarItems? and s.active userId
		markUserEvent userId, 'calendarItemsUpdate' if services.length > 0

		@unblock() if async

		for externalService in services
			result = null
			try
				result = externalService.getCalendarItems userId, from, to
			catch e
				console.log 'error while fetching calendarItems from service.', e
				handleServiceError externalService.name, userId, e
				errors.push e
				continue

			for calendarItem in result ? []
				val = CalendarItems.findOne
					fetchedBy: calendarItem.fetchedBy
					externalId: calendarItem.externalId

				content = calendarItem.content
				if content? and (not content.type? or content.type is 'homework')
					content.type = 'quiz' if /^(so|schriftelijke overhoring|(luister\W?)?toets)\b/i.test content.description
					content.type = 'test' if /^(proefwerk|pw|examen|tentamen)\b/i.test content.description
				calendarItem.content = content

				if val? and Meteor.isServer
					delete calendarItem._id
					mergeUserIdsField = (fieldName) ->
						calendarItem[fieldName] = _(val[fieldName])
							.concat calendarItem[fieldName]
							.uniq()
							.value()
					mergeUserIdsField 'userIds'
					mergeUserIdsField 'usersDone'
					CalendarItems.update val._id, { $set: calendarItem }, modifier: no
				else
					CalendarItems.insert calendarItem

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
		@unblock()

		# TODO: Store doneQueries so that we can cache them, example:
		# tho -> fetch persons -> store persons
		# thom -> tho is substring of thom, we can locally filter the results
		#         of 'tho' instead of having to request it from the externalService

		check query, String
		check type, Match.Optional String
		check userId, String

		query = query.toLowerCase()
		result = []

		services = _.filter Services, (s) -> s.getPersons? and s.active userId
		for service in services
			result = result.concat service.getPersons userId, query, type

		result

	###*
	# Returns the classes from externalServices for the given `userId`
	# @method getExternalClasses
	# @param [userId=this.userId] {String} The ID of the user to get the classes from.
	# @return {SchoolClass[]} The external classes as SchoolClasses
	###
	'getExternalClasses': (userId = @userId) ->
		@unblock()

		check userId, String

		courseInfo = getCourseInfo userId
		result = []

		unless courseInfo?
			throw new Meteor.Error 'unauthorized'

		{ year, schoolVariant } = courseInfo

		services = _.filter Services, (s) -> s.getClasses? and s.active userId
		for service in services
			try
				classes = service.getClasses userId
			catch e
				console.log 'error while fetching classes from service.', e
				continue

			result = result.concat classes.map (c) ->
				_class = Classes.findOne
					$or: [
						{ name: $regex: c.name, $options: 'i' }
						{ abbreviations: c.abbreviation.toLowerCase() }
					]
					schoolVariant: schoolVariant
					year: year

				unless _class?
					scholierenClass = ScholierenClasses.findOne do (c) -> (sc) ->
						sc.name
							.toLowerCase()
							.indexOf(c.name.toLowerCase()) > -1

					console.log c, scholierenClass

					_class = new SchoolClass(
						c.name.toLowerCase(),
						c.abbreviation.toLowerCase(),
						year,
						schoolVariant
					)
					_class.scholierenClassId = scholierenClass?.id
					_class.fetchedBy = service.name
					_class.externalInfo =
						id: c.id
						abbreviation: c.abbreviation
						name: c.name

					# Insert the class and set the id to the class object.
					# This is needed because we removed the OjectID method we were using
					# before.
					_class._id = Classes.insert _class

				_class

		result

	###*
	# Gets the assignments for the user with the given `userId`.
	# @method getExternalAssignments
	# @param [userId=this.userId] {String} The ID of the user to get the assignments for.
	# @return {Assignment[]}
	###
	'getExternalAssignments': (userId = @userId) ->
		@unblock()

		check userId, String

		user = Meteor.users.findOne userId
		result = []

		unless user?
			throw new Meteor.Error 'unauthorized'

		services = _.filter Services, (s) -> s.getAssignments? and s.active userId
		for service in services
			assignments = service.getAssignments userId
			result = result.concat assignments

		result

	'getServiceSchools': (serviceName, query) ->
		@unblock()

		check serviceName, String
		check query, String

		service = _.find Services, (s) -> s.name is serviceName

		unless service?
			throw new Meteor.Error 'notFound', "No service with name '#{serviceName}' found"

		unless service.getSchools?
			throw new Meteor.Error 'incorrectRequest', "#{serviceName} doesn't have an `getSchools` method"

		try
			result = service.getSchools query
		catch e
			handleServiceError service.name, @userId, e
			throw new Meteor.Error 'externalError', "Error while retreiving schools from #{serviceName}"

		for school in result
			val = Schools.findOne "externalIds.#{serviceName}": school.id

			unless val?
				s = new School school.name, school.url
				s.externalIds[serviceName] = school.id
				Schools.insert s

		Schools.find(
			"externalIds.#{serviceName}": $exists: yes
			name: $regex: query, $options: 'i'
		).fetch()

	'getSchools': (query) ->
		check query, String
		@unblock()

		services = _.filter Services, (s) -> s.getSchools?
		for service in services
			Meteor.call 'getServiceSchools', service.name, query

		Schools.find(
			name: $regex: query, $options: 'i'
		).fetch()

	'getServiceProfileData': (serviceName, userId = @userId) ->
		@unblock()

		check serviceName, String
		check userId, String

		service = _.find Services, (s) -> s.name is serviceName

		unless service?
			throw new Meteor.Error 'notFound', "No service with name '#{serviceName}' found"

		unless service.getProfileData?
			throw new Meteor.Error(
				'incorrectRequest'
				"#{serviceName} doesn't have an `getProfileData` method"
			)

		try
			service.getProfileData userId
		catch e
			handleServiceError service.name, userId, e
			throw new Meteor.Error(
				'externalError'
				"Error while retreiving profile data from #{serviceName}"
				e.toString()
			)

	###*
	# Gets the profile data for every enabled external service as an object. Key
	# is set to the dbname of the service, the value is set to the profile data of
	# that service.
	#
	# @method getProfileData
	# @param [userId=this.userId] {String} The ID of the user to get the profile data for.
	# @return {Object}
	###
	'getProfileData': (userId = @userId) ->
		@unblock()
		check userId, String

		services = _.filter Services, (s) -> s.active userId

		res = {}
		for service in services
			data = Meteor.call 'getServiceProfileData', service.name, userId
			if data.courseInfo?
				data.courseInfo.schoolVariant = normalizeSchoolVariant data.courseInfo.schoolVariant
			res[service.name] = data
		res

	###*
	# Returns an array containg info about available services.
	# @method getModuleInfo
	# @param [userId=this.userId] {String} The ID of the user to use for the service info.
	# return {Object[]} An array containg objects that hold the info about all the services.
	###
	'getModuleInfo': (userId = @userId) ->
		check userId, String

		_.map Services, (s) ->
			name: s.name
			friendlyName: s.friendlyName
			active: s.active userId
			hasData: s.hasData userId
			loginNeeded: s.loginNeeded

	# TODO: should we have checks to ensure that no data has been stored yet for
	# the service?
	#
	# I don't know if it's useful to call this function while there's
	# already data (maybe if an user wants to relogin on another account for
	# example, or we need to do some weird db management which isn't really
	# possible on another way, than to relogin everybody on the services).
	#
	# But it can also make the code less error prone, idk. The best thing to do
	# now is to make Service#createData for each server not break stuff if it's
	# called multiple times on the same user.
	'createServiceData': (serviceName, params...) ->
		@unblock()

		check serviceName, String

		service = _.find Services, (s) -> s.name is serviceName
		unless service?
			throw new Meteor.Error 'notfound', "No module with the name '#{serviceName}' found."

		res = service.createData params..., @userId

		if _.isError res # custom error
			throw new Meteor.Error 'error', 'Other error.', res.message
			handleServiceError service.name, @userId, res

		else if not service.loginNeeded # res is true if service is active.
			service.active @userId, res

		else if res is false # login credentials wrong.
			throw new Meteor.Error 'forbidden', 'Login credentials incorrect.'

		Meteor.call 'getServiceProfileData', serviceName, @userId

	'deleteServiceData': (serviceName, userId = @userId) ->
		@unblock()

		check serviceName, String
		check userId, String

		service = _.find Services, (s) -> s.name is serviceName
		if service?
			service.storedInfo userId, null
		else
			throw new Meteor.Error 'notfound', "No module with the name '#{serviceName}' found."

handleServiceError = (serviceName, userId, error) ->
	ExternalServiceErrors.insert
		service: serviceName
		userId: userId
		date: new Date
		error: error

Meteor.publish 'externalCalendarItems', (from, to) ->
	check from, Date
	check to, Date

	@unblock()
	unless @userId?
		@ready()
		return undefined

	from = from.date().addDays -(from.getDay() % 2)
	to = to.date().addDays to.getDay() % 2

	handle = Helpers.interval (=>
		Meteor.call 'updateCalendarItems', @userId, yes, from, to
	), 1000 * 60 * 20 # 20 minutes

	@onStop ->
		Meteor.clearInterval handle

	CalendarItems.find
		userIds: @userId
		startDate: $gte: from
		endDate: $lte: to

Meteor.publish 'externalGrades', (options) ->
	check options, Object
	{ classId, onlyRecent } = options

	@unblock()
	unless @userId?
		@ready()
		return undefined

	handle = Helpers.interval (=>
		Meteor.call 'updateGrades', @userId, no, yes
	), 1000 * 60 * 20 # 20 minutes

	@onStop ->
		Meteor.clearInterval handle

	date = Date.today().addDays -4

	query = ownerId: @userId
	query.classId = classId if classId?
	query.dateFilledIn = { $gte: date } if onlyRecent
	Grades.find query

Meteor.publish 'externalStudyUtils', (classId) ->
	check classId, String

	@unblock()
	unless @userId?
		@ready()
		return undefined

	handle = Helpers.interval (=>
		Meteor.call 'updateStudyUtils', @userId, no, yes
	), 1000 * 60 * 20 # 20 minutes

	@onStop ->
		Meteor.clearInterval handle

	StudyUtils.find
		ownerId: @userId
		classId: classId

Meteor.publish 'moduleInfo', ->
	@unblock()

	Meteor.users.find(@userId)._depend()
	res = Meteor.call 'getModuleInfo'

	@added('moduleInfo', new Mongo.ObjectId(), i) for i in res
	@ready()

@Services = Services
@ExternalServicesConnector = ExternalServicesConnector

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
