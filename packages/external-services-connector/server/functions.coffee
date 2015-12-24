# REVIEW: Better way to do this?
GRADES_INVALIDATION_TIME         = 1000 * 60 * 20 # 20 minutes
STUDYUTILS_INVALIDATION_TIME     = 1000 * 60 * 20 # 20 minutes
CALENDAR_ITEMS_INVALIDATION_TIME = 1000 * 60 * 10 # 10 minutes

markUserEvent = (userId, name) ->
	check userId, String
	check name, String
	Meteor.users.update userId, $set: "events.#{name}": new Date

###*
# Updates the grades in the database for the given `userId` or the user
# in of current connection, unless the grades were updated shortly before.
#
# @method updateGrades
# @param userId {String} `userId` overwrites the `this.userId` which is used by default which is used by default.
# @param [forceUpdate=false] {Boolean} If true the grades will be forced to update, otherwise the grades will only be updated if they weren't updated in the last 20 minutes.
# @return {Error[]} An array containing errors from ExternalServices.
###
updateGrades = (userId, forceUpdate = no) ->
	check userId, String
	check forceUpdate, Boolean

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
			ExternalServicesConnector.handleServiceError externalService.name, userId, e
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
# @param userId {String} `userId` overwrites the `this.userId` which is used by default which is used by default.
# @param [forceUpdate=false] {Boolean} If true the utils will be forced to update, otherwise the utils will only be updated if they weren't updated in the last 20 minutes.
# @return {Error[]} An array containing errors from ExternalServices.
###
updateStudyUtils = (userId, forceUpdate = no) ->
	check userId, String
	check forceUpdate, Boolean

	user = Meteor.users.findOne userId
	studyUtilsUpdateTime = user.events.studyUtilsUpdate?.getTime()
	errors = []

	if not forceUpdate and studyUtilsUpdateTime? and
	studyUtilsUpdate > _.now() - STUDYUTILS_INVALIDATION_TIME
		return errors

	services = _.filter Services, (s) -> s.getStudyUtil? and s.active userId
	markUserEvent userId, 'studyUtilsUpdate' if services.length > 0

	for externalService in services
		result = null
		try
			result = externalService.getStudyUtils userId
		catch e
			console.log 'error while fetching studyUtils from service.', e
			ExternalServicesConnector.handleServiceError externalService.name, userId, e
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
# @param userId {String} `userId` overwrites the `this.userId` which is used by default which is used by default.
# @param [from] {Date} The date from which to get the calendarItems from.
# @param [to] {Date} The date till which to get the calendarItems of.
# @return {Error[]} An array containing errors from ExternalServices.
###
updateCalendarItems = (userId, from, to) ->
	check userId, String
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

	for externalService in services
		result = null
		try
			result = externalService.getCalendarItems userId, from, to
		catch e
			console.log 'error while fetching calendarItems from service.', e
			ExternalServicesConnector.handleServiceError externalService.name, userId, e
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
# @param userId {String}
# @return {ExternalPerson[]}
###
getPersons = (query, type = undefined, userId) ->
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
# @param userId {String} The ID of the user to get the classes from.
# @return {SchoolClass[]} The external classes as SchoolClasses
###
getExternalClasses = (userId) ->
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
# @param userId {String} The ID of the user to get the assignments for.
# @return {Assignment[]}
###
getExternalAssignments = (userId) ->
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

getServiceSchools = (serviceName, query, userId) ->
	check serviceName, String
	check query, String
	check userId, Match.Optional String

	service = _.find Services, (s) -> s.name is serviceName

	unless service?
		throw new Meteor.Error 'notFound', "No service with name '#{serviceName}' found"

	unless service.getSchools?
		throw new Meteor.Error 'incorrectRequest', "#{serviceName} doesn't have an `getSchools` method"

	try
		result = service.getSchools query
	catch e
		ExternalServicesConnector.handleServiceError service.name, userId, e
		throw new Meteor.Error 'externalError', "Error while retreiving schools from #{serviceName}"

	for school in result
		val = Schools.findOne "externalInfo.#{serviceName}.id": school.id

		unless val?
			s = new School school.name, school.genericUrl
			s.externalInfo[serviceName] =
				id: school.id
				url: school.url
			Schools.insert s

	Schools.find(
		"externalInfo.#{serviceName}": $exists: yes
		name: $regex: query, $options: 'i'
	).fetch()

getSchools = (query, userId) ->
	check query, String
	check userId, Match.Optional String

	services = _.filter Services, (s) -> s.getSchools?
	for service in services
		getServiceSchools service.name, query, userId

	Schools.find(
		name: $regex: query, $options: 'i'
	).fetch()

getServiceProfileData = (serviceName, userId) ->
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
		ExternalServicesConnector.handleServiceError service.name, userId, e
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
# @param userId {String} The ID of the user to get the profile data for.
# @return {Object}
###
getProfileData = (userId) ->
	check userId, String

	services = _.filter Services, (s) -> s.active userId

	res = {}
	for service in services
		data = getServiceProfileData service.name, userId
		if data.courseInfo?
			data.courseInfo.schoolVariant = normalizeSchoolVariant data.courseInfo.schoolVariant
		res[service.name] = data
	res

###*
# Returns an array containg info about available services.
# @method getModuleInfo
# @param userId {String} The ID of the user to use for the service info.
# return {Object[]} An array containg objects that hold the info about all the services.
###
getModuleInfo = (userId) ->
	check userId, String

	_.map Services, (s) ->
		name: s.name
		friendlyName: s.friendlyName
		active: s.active userId
		hasData: s.hasData userId
		loginNeeded: s.loginNeeded

# wat.
@updateGrades = updateGrades
@updateStudyUtils = updateStudyUtils
@updateCalendarItems = updateCalendarItems
@getPersons = getPersons
@getExternalClasses = getExternalClasses
@getExternalAssignments = getExternalAssignments
@getServiceSchools = getServiceSchools
@getSchools = getSchools
@getServiceProfileData = getServiceProfileData
@getProfileData = getProfileData
@getModuleInfo = getModuleInfo
