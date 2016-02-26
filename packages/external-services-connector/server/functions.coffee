# REVIEW: Better way to do this?
GRADES_INVALIDATION_TIME         = 1000 * 60 * 20 # 20 minutes
STUDYUTILS_INVALIDATION_TIME     = 1000 * 60 * 20 # 20 minutes
CALENDAR_ITEMS_INVALIDATION_TIME = 1000 * 60 * 10 # 10 minutes

hasChanged = (a, b, omitExtra = []) ->
	clone = (obj) -> EJSON.parse EJSON.stringify obj

	omitKeys = [ '_id' ].concat omitExtra
	omit = (obj) ->
		if _.isArray obj
			_.map obj, omit
		else if _.isPlainObject obj
			for key in omitKeys
				obj = _.omit obj, key

			for key of obj
				if obj[key] is null
					delete obj[key]
				else
					obj[key] = omit obj[key]

			obj
		else
			obj

	not EJSON.equals(
		omit clone a
		omit clone b
	)

markUserEvent = (userId, name) ->
	check userId, String
	check name, String
	Meteor.users.update userId, $set: "events.#{name}": new Date

diffAndInsertFiles = (userId, files) ->
	vals = Files.find(
		externalId: $in: _.pluck files, 'externalId'
	).fetch()

	for file in files
		val = _.find vals,
			externalId: file.externalId

		file.userIds = val?.userIds ? []
		if userId not in file.userIds
			file.userIds.push userId

		if val?
			Schemas.Files.clean file

			if hasChanged val, file
				Files.update val._id, { $set: file }, (->)
		else
			Files.insert file

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

	inserts = []
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

		grades = Grades.find(
			ownerId: userId
			fetchedBy: externalService.name
			externalId: $in: _.pluck result, 'externalId'
		).fetch()

		for grade in result ? []
			continue unless grade?
			Schemas.Grades.clean grade
			val = _.find grades,
				externalId: grade.externalId
				fetchedBy: grade.fetchedBy

			if val?
				if hasChanged val, grade, [ 'dateTestMade' ]
					Grades.update val._id, { $set: grade }, (->)
			else
				inserts.push grade

	Grades.batchInsert inserts if inserts.length > 0
	errors

###*
# Updates the studyUtils in the database for the given `userId` or the user
# in of current connection, unless the utils were updated shortly before.
#
# @method updateStudyUtils
# @param userId {String} `userId` overwrites the `this.userId` which is used by default.
# @param [forceUpdate=false] {Boolean} If true the utils will be forced to update, otherwise the utils will only be updated if they weren't updated in the last 20 minutes.
# @return {Error[]} An array containing errors from ExternalServices.
###
updateStudyUtils = (userId, forceUpdate = no) ->
	check userId, String
	check forceUpdate, Boolean
	UPDATE_CHECK_OMITTED = [
		'creationDate'
		'visibleFrom'
		'visibleTo'
		'updatedOn'
		'userIds'
		'classId'
	]

	user = Meteor.users.findOne userId
	studyUtilsUpdateTime = user.events.studyUtilsUpdate?.getTime()
	errors = []

	if not forceUpdate and
	studyUtilsUpdateTime? and
	studyUtilsUpdateTime > _.now() - STUDYUTILS_INVALIDATION_TIME
		return errors

	services = _.filter Services, (s) -> s.getStudyUtils? and s.active userId
	markUserEvent userId, 'studyUtilsUpdate' if services.length > 0

	inserts = []
	for externalService in services
		result = null
		try
			result = externalService.getStudyUtils userId
		catch e
			console.log 'error while fetching studyUtils from service.', e
			ExternalServicesConnector.handleServiceError externalService.name, userId, e
			errors.push e
			continue

		studyUtils = StudyUtils.find({
			fetchedBy: externalService.name
			externalInfo: $in: _.pluck result, 'externalInfo'
		}, {
			transform: null
		}).fetch()

		for studyUtil in result.studyUtils ? []
			val = _.find studyUtils,
				externalInfo: studyUtil.externalInfo
				classId: studyUtil.classId ? null

			if val?
				studyUtil.userIds = _(val.userIds)
					.concat studyUtil.userIds
					.uniq()
					.value()

				if hasChanged val, studyUtil, UPDATE_CHECK_OMITTED
					studyUtil.updatedOn = new Date()
					StudyUtils.update val._id, { $set: studyUtil }, (->)
				else if studyUtil.userIds.length isnt val.userIds.length
					StudyUtils.update val._id, { $set: studyUtil }, (->)
			else
				inserts.push studyUtil

		diffAndInsertFiles userId, result.files

	StudyUtils.batchInsert inserts if inserts.length > 0
	errors

# REVIEW: Should we have different functions for absenceInfo and calendarItems?
# TODO: think out some throttling for this.
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

	# TODO: fix using `events.calendarItemsUpdate` here.

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

		calendarItems = CalendarItems.find(
			fetchedBy: externalService.name
			$or: [
				{ externalId: $in: _.pluck result.calendarItems, 'externalId' }
				{
					classId: $in: _.pluck result.calendarItems, 'classId'
					startDate: $in: _.pluck result.calendarItems, 'startDate'
					endDate: $in: _.pluck result.calendarItems, 'endDate'
					userIds: userId
				}
			]
		).fetch()

		absences = Absences.find(
			userId: userId
			fetchedBy: externalService.name
			externalId: $in:
				_(result.absenceInfos)
					.pluck 'absenceInfo.externalId'
					.compact()
					.value()
		).fetch()

		for calendarItem in result.calendarItems
			val = _.find calendarItems,
				externalId: calendarItem.externalId

			val ?= _.find calendarItems, (x) ->
				x.classId is calendarItem.classId and
				EJSON.equals(x.startDate, calendarItem.startDate) and
				EJSON.equals(x.endDate, calendarItem.endDate)

			content = calendarItem.content
			if content? and (not content.type? or content.type is 'homework')
				content.type = 'quiz' if /^(so|schriftelijke overhoring|(\w+\W?)?(toets|test))\b/i.test content.description
				content.type = 'test' if /^(proefwerk|pw|examen|tentamen)\b/i.test content.description
			calendarItem.content = content

			obj = _.omit calendarItem, 'absenceInfo'

			if val?
				obj.fileIds = _.pluck obj.files, '_id'
				Schemas.CalendarItems.clean obj

				mergeUserIdsField = (fieldName) ->
					obj[fieldName] = _(val[fieldName])
						.concat obj[fieldName]
						.uniq()
						.value()
				mergeUserIdsField 'userIds'
				mergeUserIdsField 'usersDone'

				if hasChanged val, obj
					CalendarItems.update val._id, { $set: obj }, (->)
			else
				CalendarItems.insert obj

		for absenceInfo in result.absenceInfos
			val = _.find absences,
				externalId: absenceInfo.externalId

			if val?
				if hasChanged val, absenceInfo
					Absences.update val._id, { $set: absenceInfo }, (->)
			else
				Absences.insert absenceInfo

		diffAndInsertFiles userId, result.files

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
				_class = new SchoolClass(
					c.name.toLowerCase(),
					c.abbreviation.toLowerCase(),
					year,
					schoolVariant
				)

				# Insert the class and set the id to the class object.
				# This is needed since the class object doesn't have an ID yet, but the
				# things further down the road requires it.
				_class._id = insertClass _.cloneDeep _class

			_class.externalInfo =
				id: c.id
				abbreviation: c.abbreviation
				name: c.name
				fetchedBy: service.name

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
	check userId, String

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

	inserts = []
	for school in result
		val = Schools.findOne "externalInfo.#{serviceName}.id": school.id

		unless val?
			s = new School school.name, school.genericUrl
			s.externalInfo[serviceName] =
				id: school.id
				url: school.url
			inserts.push s

	Schools.batchInsert inserts if inserts.length > 0
	Schools.find(
		"externalInfo.#{serviceName}": $exists: yes
		name: $regex: query, $options: 'i'
	).fetch()

getSchools = (query, userId) ->
	check query, String
	check userId, String

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

AD_STRING = '\n\n---\nVerzonden vanuit <a href="http://www.simplyHomework.nl">simplyHomework</a>.'
###*
# @method updateMessages
# @param {String} userId
# @param {Number} offset
# @param {String[]} folders
# @param {Boolean} [forceUpdate=false]
# @return {Error[]}
###
updateMessages = (userId, offset, folders, forceUpdate = no) ->
	check userId, String
	check offset, Number
	check folders, [String]
	check forceUpdate, Boolean

	services = _.filter Services, (s) -> s.getMessages? and s.active userId
	errors = []
	LIMIT = 20
	NEW_MESSAGES_LIMIT = 5

	for folder in folders
		for service in services
			handleErr = (e) ->
				console.log 'error while fetching messages from service.', e
				ExternalServicesConnector.handleServiceError service.name, userId, e
				errors.push e

			results = []
			try # fetch the messages asked for
				results.push(
					service.getMessages folder, offset, LIMIT, userId
				)
			catch e
				handleErr e
				continue

			if offset > 0 # fetch new messages at top, unless we are asked for them.
				try
					results.push(
						service.getMessages folder, 0, NEW_MESSAGES_LIMIT, userId
					)
				catch e
					handleErr e
					continue

			messages = _(results)
				.pluck 'messages'
				.flatten()
				.value()
			files = _(results)
				.pluck 'files'
				.flatten()
				.value()

			for message in messages
				continue unless message?
				if message.body?
					message.body = message.body.replace AD_STRING, ''
				message.fetchedFor = [ userId ]

				val = Messages.findOne
					externalId: message.externalId
					fetchedBy: message.fetchedBy

				if val?
					mergeUserIdsField = (fieldName) ->
						message[fieldName] = _(val[fieldName])
							.concat message[fieldName]
							.uniq()
							.value()
					mergeUserIdsField 'fetchedFor'
					mergeUserIdsField 'readBy'

					if hasChanged val, message
						Messages.update message._id, message, validate: no
				else
					Messages.insert message

			diffAndInsertFiles userId, files

	errors

sendMessage = (subject, body, recipients, service, userId) ->
	check subject, String
	check body, String
	check recipients, [String]
	check service, String
	check userId, String

	body += AD_STRING

	service = _.find Services, (s) -> s.name is service and s.sendMessage? and s.active userId
	if not service?
		throw new Meteor.Error 'not-supported'

	service.sendMessage subject, body, recipients, userId

replyMessage = (id, all, body, service, userId) ->
	check id, String
	check all, Boolean
	check body, String
	check service, String
	check userId, String

	message = Messages.findOne
		_id: id
		fetchedFor: @userId
	unless message?
		throw new Meteor.Error 'message-not-found'

	id = _(message.externalId).split('_').last()

	service = _.find Services, (s) -> s.name is service and s.getMessages? and s.active userId
	serivce.replyMessage id, all, body, userId

###*
# Returns an array containing info about available services.
# @method getModuleInfo
# @param userId {String} The ID of the user to use for the service info.
# return {Object[]} An array containing objects that hold the info about all the services.
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
@updateMessages = updateMessages
@sendMessage = sendMessage
@replyMessage = replyMessage
@getModuleInfo = getModuleInfo
