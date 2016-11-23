import Future from 'fibers/future'
import WaitGroup from 'meteor/simply:waitgroup'
import { ExternalServicesConnector, getServices } from '../connector.coffee'
import { handleCollErr, hasChanged, diffObjects, diffAndInsertFiles } from './util.coffee'
import { calendarItemsInvalidationTime } from '../constants.coffee'

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
		lock = {
			userId
			start
			end
			callbacks: [ cb ]
		}
		calendarItemsLocks.push lock

		lockTick = ->
			if lock.callbacks.length > 0
				lock.callbacks.shift() ->
					lockTick()
			else
				_.pull calendarItemsLocks, lock

		Meteor.defer lockTick

	lock

getLockSync = (userId, start, end) ->
	fut = new Future()
	getLock userId, start, end, (done) -> fut.return done
	fut.wait()

calendarItemFetches = [] # { userId, start, end, time }
shouldFetch = (userId, start, end) ->
	start = start.date()
	end = end.date()

	fetches = _(calendarItemFetches)
		.reject (f) -> _.now() - f.time > calendarItemsInvalidationTime
		.filter { userId }
		.value()

	dates = _.chain()
		.range Helpers.daysRange(start, end) + 1
		.map (n) -> start.addDays n
		.reject (d) -> _.some fetches, (f) -> f.start <= d <= f.end
		.value()

	if dates.length > 0
		[
			_.min dates
			_.max dates
		]
	else
		undefined

addFetch = (userId, start, end) ->
	calendarItemFetches.push
		userId: userId
		start: start
		end: end
		time: new Date()

# cleanup stale entries to prevent memory leak
Meteor.setInterval (->
	_.remove calendarItemFetches, (f) ->
		_.now() - f.time > calendarItemsInvalidationTime
), ms.minutes 2.5

# REVIEW: Should we have different functions for absenceInfo and calendarItems?
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
export updateCalendarItems = (userId, from, to) ->
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
	OVERWRITE_IGNORE = [
		'externalInfo'
		'externalInfos'
		'_id'
		'startDate'
		'endDate'
		'fullDay'
		'usersDone'
	]

	user = Meteor.users.findOne userId
	errors = []

	done = getLockSync userId, from, to

	range = shouldFetch userId, from, to
	unless range?
		done()
		return

	[ from, to ] = range
	services = getServices userId, 'getCalendarItems'
	results = {}

	group = new WaitGroup
	services.forEach (service) ->
		 group.defer ->
			try
				results[service.name] =
					result: service.getCalendarItems userId, from, to
			catch error
				results[service.name] = { error }
	group.wait()

	absences = []
	files = []
	calendarItems = []

	for service in services
		{ result, error } = results[service.name]
		if error?
			ExternalServicesConnector.handleServiceError(
				service.name,
				userId,
				error
			)
			errors.push error
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
				for [ key, val ] in _.pairs(item) when key not in OVERWRITE_IGNORE
					old[key] = val if (
						switch key
							when 'scrapped' then val is true
							when 'description' then service.name isnt 'zermelo'
							when 'location' then val.toLowerCase() isnt old[key].toLowerCase()
							else not _.isEmpty val
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

	if calendarItems.length > 0
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

	addFetch userId, from, to
	done()
	errors
