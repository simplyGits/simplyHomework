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
	), ms.minutes 20

	cursor =
		CalendarItems.find {
			userIds: userId
			startDate: $gte: from
			endDate: $lte: to
		}, {
			sort: startDate: 1
		}

	transform = (doc) ->
		if doc.usersDone?
			doc.usersDone = (
				if userId in doc.usersDone then [ userId ]
				else []
			)
		doc

	absencesObservers = {}

	observer = cursor.observeChanges
		added: (id, doc) =>
			@added 'calendarItems', id, transform doc

			absencesObservers[id] ?= Absences.find({
				calendarItemId: id
				userId: userId
			}, {
				limit: 1
			}).observeChanges
				added: (id, doc) => @added 'absences', id, doc
				removed: (id) => @removed 'absences', id

		changed: (id, doc) =>
			@changed 'calendarItems', id, transform doc

		removed: (id) =>
			@removed 'calendarItems', id

			absencesObservers[id].stop()
			delete absencesObservers[id]

	@onStop ->
		Meteor.clearInterval handle
		observer.stop()

		for observer in _.values absencesObservers
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
	), ms.minutes 20

	@onStop ->
		Meteor.clearInterval handle

	CalendarItems.find {
		userIds: $in: userIds
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
	), ms.minutes 20

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
	), ms.minutes 20

	@onStop ->
		Meteor.clearInterval handle

	query = userIds: @userId
	query.classId = classId if classId?
	query.updatedOn =  { $gte: Date.today().addDays -3 } if onlyRecent
	StudyUtils.find query

Meteor.publish 'messages', (offset, folders, unreadOnly = no) ->
	check offset, Number
	check folders, [String]
	check unreadOnly, Boolean

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
	), ms.minutes 5

	@onStop ->
		Meteor.clearInterval handle

	query =
		fetchedFor: userId
		folder: $in: folders
	query.isRead = no if unreadOnly
	Messages.find query,
		sort:
			sendDate: -1
		limit: offset + 20

Meteor.publish 'serviceUpdates', ->
	@unblock()
	userId = @userId
	unless userId?
		@ready()
		return undefined

	handle = Helpers.interval (->
		fetchServiceUpdates userId
	), ms.minutes 45

	@onStop ->
		Meteor.clearInterval handle

	ServiceUpdates.find { userId }
