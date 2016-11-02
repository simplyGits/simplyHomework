Future = require 'fibers/future'
{ Services, ExternalServicesConnector, getServices } = require './connector.coffee'

# REVIEW: Better way to do this?
GRADES_INVALIDATION_TIME         = ms.minutes 20
STUDYUTILS_INVALIDATION_TIME     = ms.minutes 20
CALENDAR_ITEMS_INVALIDATION_TIME = ms.minutes 10
SERVICE_UPDATE_INVALIDATION_TIME = ms.minutes 30
PERSON_CACHE_INVALIDATION_TIME   = ms.minutes 15

###*
# @method handleCollErr
# @param {Error} e
###
handleCollErr = (e) ->
	if e?
		Kadira.trackError(
			'external-services-connector'
			e.message
			{ stacks: e.stack }
		)

###*
# @method clone
# @param {Object} obj
# @return {Object}
###
clone = (obj) -> EJSON.parse EJSON.stringify obj
###*
# Recursively omits the given keys from the given array or object.
# If `obj` isn't an array or object, this function will just return `obj`.
# @method omit
# @param {any} obj
# @param {String[]} keys
# @return {Object}
###
omit = (obj, keys) ->
	if _.isArray obj
		_.map obj, (x) -> omit x, keys
	else if _.isPlainObject obj
		for key in keys
			obj = _.omit obj, key

		for key of obj
			if obj[key] is null
				delete obj[key]
			else
				obj[key] = omit obj[key], keys

		obj
	else
		obj

###*
# @method hasChanged
# @param {Object} a
# @param {Object} b
# @param {String[]} omitExtra
# @return {Boolean}
###
hasChanged = (a, b, omitExtra = []) ->
	omitKeys = [ '_id' ].concat omitExtra

	not EJSON.equals(
		omit clone(a), omitKeys
		omit clone(b), omitKeys
	)

###*
# @method diffObjects
# @param {Object} a
# @param {Object} b
# @param {String[]} [exclude=[]]
# @param {Boolean} [ignoreCasing=true]
# @return {Object[]}
###
diffObjects = (a, b, exclude = [], ignoreCasing = yes) ->
	a = clone(a)
	b = clone(b)
	omitKeys = [ '_id' ].concat exclude

	_(_.keys a)
		.concat _.keys b
		.uniq()
		.reject (x) -> x in omitKeys
		.map (key) ->
			key: key
			prev: a[key]
			next: b[key]
		.reject (obj) ->
			EJSON.equals(obj.prev, obj.next) or
			(
				ignoreCasing and
				_.isString(obj.prev) and _.isString(obj.next) and
				obj.prev.trim().toLowerCase() is obj.next.trim().toLowerCase()
			)
		.value()

###*
# @method markUserEvent
# @param {String} userId
# @param {String} name
###
markUserEvent = (userId, name) ->
	check userId, String
	check name, String
	Meteor.users.update userId, $set: "events.#{name}": new Date

###*
# @method checkAndMarkUserEvent
# @param {String} userId
# @param {String} name
# @param {Number} invalidationTime
# @param {Boolean} [force=false]
# @return {Boolean}
###
checkAndMarkUserEvent = (userId, name, invalidationTime, force = no) ->
	check userId, String
	check name, String
	check invalidationTime, Number
	check force, Boolean

	updateTime = getEvent name, userId
	if not force and updateTime? and updateTime > _.now() - invalidationTime
		no
	else
		markUserEvent userId, name
		yes

###*
# @method diffAndInsertFiles
# @param {String} userId
# @param {ExternalFile[]} files
# @return {Object}
###
diffAndInsertFiles = (userId, files) ->
	vals = Files.find(
		externalId: $in: _.pluck files, 'externalId'
	).fetch()

	res = {}

	for file in files
		val = _.find vals,
			externalId: file.externalId

		id = file._id
		if val?
			ExternalFile.schema.clean file
			id = val._id

			# use the version with the newest creationDate
			if ((not file.creationDate or not file.creationDate) or file.creationDate > val.creationDate) and
			hasChanged val, file, [ 'downloadInfo', 'size' ]
				delete file._id
				Files.update val._id, { $set: file }, handleCollErr
		else
			id = Files.insert file, handleCollErr

		res[file._id] = id if file._id?

	res

###*
# Updates the grades in the database for the given `userId` or the user
# in of current connection, unless the grades were updated shortly before.
#
# @method updateGrades
# @param userId {String}
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

	services = getServices userId, 'getGrades'
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
			Grade.schema.clean grade, removeEmptyStrings: no
			val = _.find grades,
				externalId: grade.externalId
				fetchedBy: grade.fetchedBy

			if val?
				if hasChanged val, grade, [ 'dateTestMade', 'previousValues' ]
					items = [ 'dateFilledIn', 'grade', 'gradeStr', 'weight' ]
					if not grade.isEnd and
					hasChanged _.pick(val, items), _.pick(grade, items)
						grade.previousValues =
							dateFilledIn: val.dateFilledIn
							grade: val.grade
							gradeStr: val.gradeStr
							weight: val.weight

					Grades.update val._id, { $set: grade }, { removeEmptyStrings: no }, handleCollErr
			else
				Grades.insert grade

	errors

###*
# Updates the studyUtils in the database for the given `userId` or the user
# in of current connection, unless the utils were updated shortly before.
#
# @method updateStudyUtils
# @param userId {String}
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

	services = getServices userId, 'getStudyUtils'
	markUserEvent userId, 'studyUtilsUpdate' if services.length > 0

	for externalService in services
		result = null
		try
			result = externalService.getStudyUtils userId
		catch e
			ExternalServicesConnector.handleServiceError externalService.name, userId, e
			errors.push e
			continue

		studyUtils = StudyUtils.find({
			fetchedBy: externalService.name
			externalInfo: $in: _.pluck result.studyUtils, 'externalInfo'
		}, {
			transform: null
		}).fetch()

		fileKeyChanges = diffAndInsertFiles userId, result.files

		for studyUtil in result.studyUtils ? []
			val = _.find studyUtils,
				externalInfo: studyUtil.externalInfo
				classId: studyUtil.classId ? null

			studyUtil.fileIds = studyUtil.fileIds.map (id) -> fileKeyChanges[id] ? id

			if val?
				studyUtil.userIds = _(val.userIds)
					.concat studyUtil.userIds
					.uniq()
					.value()

				if hasChanged val, studyUtil, UPDATE_CHECK_OMITTED
					studyUtil.updatedOn = new Date()
					StudyUtils.update val._id, { $set: studyUtil }, handleCollErr
				else if studyUtil.userIds.length isnt val.userIds.length
					StudyUtils.update val._id, { $set: studyUtil }, handleCollErr
			else
				StudyUtils.insert studyUtil

	errors

calendarItemsLocks = [] # { userId, start, end, callbacks }
getLock = (userId, start, end, cb) ->
	lock = _.find(
		calendarItemsLocks
		(l) ->
			l.userId is userId and
			(l.start <= start <= l.end or l.start <= end <= l.end)
	)

	if lock?
		lock.callbacks.push cb
	else
		lock =
			start: start
			end: end
			callbacks: [ cb ]
		calendarItemsLocks.push lock

		removeLock = ->
			if lock.callbacks.length > 0
				lock.callbacks.shift() ->
					removeLock()
			else
				_.pull calendarItemsLocks, lock

		Meteor.defer removeLock

	lock

getLockSync = (userId, start, end) ->
	fut = new Future()
	getLock userId, start, end, (done) -> fut.return done
	fut.wait()

# REVIEW: Do we want to call `.date` on each date object here to make sure we
# don't pass date objects with a time attached to them to external services?
# REVIEW: Should we have different functions for absenceInfo and calendarItems?
# TODO: think out some throttling for this.
###*
# Updates the CalendarItems in the database for the given `userId` or the user
# in of current connection, unless the utils were updated shortly before.
#
# @method updateCalendarItems
# @param userId {String}
# @param [from] {Date} The date from which to get the calendarItems from.
# @param [to] {Date} The date till which to get the calendarItems of.
# @return {Error[]} An array containing errors from ExternalServices.
###
updateCalendarItems = (userId, from, to) ->
	check userId, String
	check from, Date
	check to, Date
	UPDATE_CHECK_OMITTED = [
		'userIds'
		'usersDone'
		'content'
		'fileIds'
		'teacher'
		'classId'
		'externalInfos'
		'scrapped'
	]

	# TODO: fix using `events.calendarItemsUpdate` here.

	user = Meteor.users.findOne userId
	calendarItemsUpdate = undefined#user.events.calendarItemsUpdate
	errors = []

	from ?= calendarItemsUpdate ? new Date().addDays -14
	if not calendarItemsUpdate? and from > new Date().addDays -14
		from = new Date().addDays -14

	to ?= new Date().addDays 7
	to = new Date().addDays(7) if to < new Date().addDays(7)

	done = getLockSync userId, from, to
	services = getServices userId, 'getCalendarItems'
	markUserEvent userId, 'calendarItemsUpdate' if services.length > 0

	absences = []
	files = []
	calendarItems = []

	for service in services
		result = undefined
		try
			result = service.getCalendarItems userId, from, to
		catch e
			ExternalServicesConnector.handleServiceError service.name, userId, e
			errors.push e
			continue

		absences = absences.concat result.absences
		files = files.concat result.files

		for item in result.calendarItems
			old = Helpers.find calendarItems,
				userIds: userId
				classId: item.classId
				startDate: item.startDate
				endDate: item.endDate
				description: item.description

			unless item.fullDay
				old ?= Helpers.find calendarItems,
					userIds: userId
					classId: item.classId
					startDate: item.startDate
					endDate: item.endDate

			if old?
				old.externalInfos[service.name] = item.externalInfo
				# HACK
				for [ key, val ] in _.pairs(item) when key not in [ 'externalInfo', 'externalInfos', '_id' ]
					old[key] = val if (
						switch key
							when 'scrapped' then val is true
							when 'description' then service.name isnt 'zermelo'
							else val?
					)

				absence = _.find result.absences, calendarItemId: item._id
				absence?.calendarItemId = old._id
			else
				item.externalInfos[service.name] = item.externalInfo
				calendarItems.push item

	fileKeyChanges = diffAndInsertFiles userId, files

	for calendarItem in calendarItems
		old = CalendarItems.findOne $or: (
			 _(calendarItem.externalInfos)
				.pairs()
				# HACK
				.map ([ name, val ]) -> "externalInfos.#{name}.id": val.id
				.value()
		)

		unless calendarItem.fullDay
			old ?= CalendarItems.findOne
				userIds: userId
				classId: calendarItem.classId
				startDate: calendarItem.startDate
				endDate: calendarItem.endDate

		content = calendarItem.content
		if content?
			if not content.type? or content.type is 'homework'
				content.type = 'quiz' if /^(so|schriftelijke overhoring|(\w+\W?)?(toets|test))\b/i.test content.description
				content.type = 'test' if /^(proefwerk|pw|examen|tentamen)\b/i.test content.description

			if content.type in [ 'test', 'exam' ]
				content.description = content.description.replace /^(proefwerk|pw|toets|test)\s?/i, ''
			else if content.type is 'quiz'
				content.description = content.description.replace /^(so|schriftelijke overhoring|toets|test)\s?/i, ''
			else if content.type is 'oral'
				content.description = content.description.replace /^(oral\W?(exam|test)|mondeling)\s?/i, ''
		calendarItem.content = content

		calendarItem.fileIds = calendarItem.fileIds.map (id) ->
			fileKeyChanges[id] ? id

		if old?
			# set the old calendarItem id for every absenceinfo fetched for this new
			# calendarItem.
			absenceInfo = _.find absences, calendarItemId: calendarItem._id
			absenceInfo?.calendarItemId = old._id

			# clean `calendarItem`, this is way faster than using the `clean` method
			# of the schema.
			delete calendarItem._id
			delete calendarItem.updateInfo
			delete calendarItem.externalInfo
			for [ key, val ] in _.pairs calendarItem
				switch val
					when '' then calendarItem[key] = null

			mergeUserIdsField = (fieldName) ->
				calendarItem[fieldName] = _(old[fieldName])
					.concat calendarItem[fieldName]
					.uniq()
					.value()
			mergeUserIdsField 'userIds'
			mergeUserIdsField 'usersDone'

			if hasChanged old, calendarItem, [ 'updateInfo' ]
				if not old.updateInfo?
					diff = diffObjects old, calendarItem, UPDATE_CHECK_OMITTED
					if diff.length > 0
						calendarItem.updateInfo =
							when: new Date()
							diff: diff

				CalendarItems.update old._id, { $set: calendarItem }, handleCollErr
		else
			delete calendarItem.externalInfo
			CalendarItems.insert calendarItem, handleCollErr

	for absence in absences
		val = Absences.findOne
			userId: userId
			fetchedBy: absence.fetchedBy
			calendarItemId: absence.calendarItemId

		if val?
			if hasChanged val, absence
				Absences.update val._id, { $set: absence }, handleCollErr
		else
			Absences.insert absence

	match = (lesson) ->
		userIds: userId
		startDate: $gte: from
		endDate: $lte: to
		type: if lesson then 'lesson' else $ne: 'lesson'
		$and: _(calendarItems)
			.pluck 'externalInfos'
			.keys()
			.uniq()
			# HACK
			.map (name) -> "externalInfos.#{name}.id": $nin: _.pluck calendarItems, "externalInfos.#{name}.id"
			.value()

	# mark lesson calendarItems that were in the db but are not returned by the
	# service as scrapped.
	CalendarItems.update match(yes), {
		$set:
			scrapped: yes
	}, {
		multi: yes
	}, handleCollErr

	# remove non-lesson calendarItems that were in the db but are not returned
	# by the service.
	CalendarItems.remove match(no), handleCollErr

	done()
	errors

personCache = []
###*
# Gets the persons matching the given `query` and `type` for the
# user with the given `userId`
#
# @method getPersons
# @param query {String}
# @param [type] {String} one of: 'teacher', 'pupil' or `undefined` to find all.
# @param userId {String}
# @return {ExternalPerson[]}
###
getPersons = (query, type = undefined, userId) ->
	check query, String
	check type, Match.Optional String
	check userId, String

	if type? and type not in [ 'teacher', 'pupil' ]
		throw new Meteor.Error 'invalid-type'

	result = []
	query = query.toLowerCase()
	types = (
		if type? then [ type ]
		else [ 'teacher', 'pupil' ]
	)

	# filter cache items from the cache based on userId, query and type.
	cached = _.filter personCache, (c) ->
		c.userId is userId and
		query.indexOf(c.query) is 0 and
		c.type in types

	# more cache filtering
	for c in cached
		if _.now() - c?.time > PERSON_CACHE_INVALIDATION_TIME
			# cache invalidated, remove item from the cache and continue.
			_.pull personCache, c
			continue

		# cache item is usable, pull the type since we have handled it and add the
		# results of the cache to the return array.
		_.pull types, c.type
		result = result.concat c.items

	# fetch items if still needed.
	if types.length > 0
		services = getServices userId, 'getPersons'

		# we don't want to store the items in result yet, because we only want to
		# create new cache items for the newely fetched items and the `result` array
		# already possibly contains items from the cache.
		fetched = []
		for service in services
			fetched = fetched.concat service.getPersons(userId, query, types)

		# cache newely fetched items by type.
		for type in types
			items = _.filter fetched, { type }
			personCache.push
				query: query
				userId: userId
				type: type
				items: _.filter fetched, { type }
				time: _.now()

		result = result.concat fetched

	result

###*
# Returns the personal classes from externalServices for the given `userId`
# @method getExternalPersonClasses
# @param userId {String} The ID of the user to get the classes from.
# @return {SchoolClass[]} The external classes as SchoolClasses
###
getExternalPersonClasses = (userId) ->
	check userId, String

	courseInfo = getCourseInfo userId
	result = []

	unless courseInfo?
		throw new Meteor.Error 'unauthorized'

	{ year, schoolVariant } = courseInfo

	services = getServices userId, 'getPersonClasses'
	for service in services
		try
			classes = service.getPersonClasses(userId).filter (c) ->
				c.name.toLowerCase() not in [
					'gemiddelde'
					'tekortpunten'
					'toetsweek'
					'combinatiecijfer'
				] and c.abbreviation.toLowerCase() not in [
					'maestro'
					'scr'
				]
		catch e
			ExternalServicesConnector.handleServiceError service.name, userId, e
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

	services = getServices userId, 'getAssignments'
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

	services = getServices userId, 'getMessages'
	errors = []
	LIMIT = 20
	MIN_NEW_MESSAGES_LIMIT = 5

	for folder in folders
		for service in services
			handleErr = (e) ->
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
						service.getMessages folder, 0, Math.min(MIN_NEW_MESSAGES_LIMIT, offset), userId
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

			fileKeyChanges = diffAndInsertFiles userId, files

			for message in messages
				continue unless message?
				if message.body?
					message.body = message.body.replace AD_STRING, ''
				message.attachmentIds = message.attachmentIds.map (id) ->
					fileKeyChanges[id] ? id

				val = Messages.findOne
					fetchedFor: userId
					externalId: message.externalId
					fetchedBy: message.fetchedBy

				if val?
					###
					mergeUserIdsField = (fieldName) ->
						message[fieldName] = _(val[fieldName])
							.concat message[fieldName]
							.uniq()
							.value()
					###

					if hasChanged val, message, [ 'notifiedOn' ]
						Messages.update message._id, message, validate: no
				else
					Messages.insert message

	errors

sendMessage = (subject, body, recipients, service, userId) ->
	check subject, String
	check body, String
	check recipients, [String]
	check service, String
	check userId, String

	body += AD_STRING

	service = _.find Services, (s) -> s.name is service and s.can userId, 'sendMessage'
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

	service = _.find Services, (s) -> s.name is service and s.can userId, 'getMessages'
	serivce.replyMessage id, all, body, userId

###*
# @fetchServiceUpdates
# @param {String} userId
# @param {Boolean} [forceUpdate=false]
# @return {Error[]}
###
fetchServiceUpdates = (userId, forceUpdate = no) ->
	check userId, String
	check forceUpdate, Boolean

	errors = []

	services = getServices userId, 'getUpdates'
	if services.length is 0 or not checkAndMarkUserEvent(
		userId
		'serviceUpdatesUpdate'
		SERVICE_UPDATE_INVALIDATION_TIME
		forceUpdate
	)
		return errors

	for service in services
		try
			updates = service.getUpdates userId
		catch e
			ExternalServicesConnector.handleServiceError service.name, userId, e
			errors.push e
			continue

		ServiceUpdates.remove {
			userId: userId
			fetchedBy: service.name
		}, handleCollErr
		for update in updates
			ServiceUpdates.insert update, handleCollErr

	errors

###*
# Returns an array containing info about available services.
# @method getModuleInfo
# @param userId {String} The ID of the user to use for the service info.
# @return {Object[]} An array containing objects that hold the info about all the services.
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
exports.updateGrades = updateGrades
exports.updateStudyUtils = updateStudyUtils
exports.updateCalendarItems = updateCalendarItems
exports.getPersons = getPersons
exports.getExternalPersonClasses = getExternalPersonClasses
exports.getExternalAssignments = getExternalAssignments
exports.getServiceSchools = getServiceSchools
exports.getSchools = getSchools
exports.getServiceProfileData = getServiceProfileData
exports.getProfileData = getProfileData
exports.updateMessages = updateMessages
exports.sendMessage = sendMessage
exports.replyMessage = replyMessage
exports.fetchServiceUpdates = fetchServiceUpdates
exports.getModuleInfo = getModuleInfo
