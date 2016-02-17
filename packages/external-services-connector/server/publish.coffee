Meteor.publish 'externalCalendarItems', (from, to) ->
	check from, Date
	check to, Date
	userId = @userId

	@unblock()
	unless userId?
		@ready()
		return undefined

	handle = Helpers.interval (->
		updateCalendarItems userId, from, to
	), 1000 * 60 * 20 # 20 minutes

	cursor =
		CalendarItems.find {
			userIds: userId
			startDate: $gte: from
			endDate: $lte: to
		}, {
			sort: startDate: 1
		}

	findAbsence = (calendarItemId) -> Absences.findOne { calendarItemId, userId }
	transform = (doc) ->
		if doc.usersDone?
			doc.usersDone = (
				if userId in doc.usersDone then [ userId ]
				else []
			)
		doc

	observer = cursor.observeChanges
		added: (id, doc) =>
			@added 'calendarItems', id, transform doc

			absence = findAbsence id
			if absence?
				@added 'absences', absence._id, absence

		changed: (id, doc) =>
			@changed 'calendarItems', id, transform doc

		removed: (id) =>
			@removed 'calendarItems', id

			absence = findAbsence id
			if absence?
				@removed 'absences', absence._id

	@onStop ->
		Meteor.clearInterval handle
		observer.stop()

	@ready()

Meteor.publish 'foreignCalendarItems', (userIds, from, to) ->
	check userIds, [String]
	check from, Date
	check to, Date

	@unblock()
	unless @userId?
		@ready()
		return undefined

	userIds = _.filter userIds, (id) ->
		Privacy.getOptions(id).publishCalendarItems

	handle = Helpers.interval (->
		for id in userIds
			updateCalendarItems id, from, to
	), 1000 * 60 * 20 # 20 minutes

	@onStop ->
		Meteor.clearInterval handle

	CalendarItems.find {
		userIds:
			$in: userIds
			$ne: @userId
		startDate: $gte: from
		endDate: $lte: to
		type: $ne: 'personal' # REVIEW: `CalendarItem::private` field?
	}, {
		sort: startDate: 1
		fields:
			usersDone: 0
			content: 0
	}

Meteor.publish 'externalGrades', (options) ->
	check options, Object
	{ classId, onlyRecent } = options

	@unblock()
	unless @userId? and (classId? or onlyRecent?)
		@ready()
		return undefined

	handle = Helpers.interval (=>
		updateGrades @userId, no
	), 1000 * 60 * 20 # 20 minutes

	@onStop ->
		Meteor.clearInterval handle

	date = Date.today().addDays -4

	query = ownerId: @userId
	query.classId = classId if classId?
	query.dateFilledIn = { $gte: date } if onlyRecent
	Grades.find query, sort: dateFilledIn: -1

Meteor.publish 'externalStudyUtils', (options) ->
	check options, Object
	{ classId, onlyRecent } = options

	@unblock()
	unless @userId?
		@ready()
		return undefined

	handle = Helpers.interval (=>
		updateStudyUtils @userId, no
	), 1000 * 60 * 20 # 20 minutes

	@onStop ->
		Meteor.clearInterval handle

	query = userIds: @userId
	query.classId = classId if classId?
	query.updatedOn =  { $gte: Date.today().addDays -4 } if onlyRecent
	StudyUtils.find query

Meteor.publish 'messages', (offset, folders) ->
	check offset, Number
	check folders, [String]

	@unblock()
	unless @userId?
		@ready()
		return undefined

	userId = @userId
	service = _.find Services, (s) -> s.getMessages? and s.active userId
	if not service?
		throw new Meteor.Error 'not-supported'

	handle = Helpers.interval (->
		updateMessages userId, offset, folders, no
	), 1000 * 60 * 5 # 5 minutes

	Messages.find {
		fetchedFor: userId
		folder: $in: folders
	}, {
		sort: sendDate: -1
		limit: offset + 20
	}
