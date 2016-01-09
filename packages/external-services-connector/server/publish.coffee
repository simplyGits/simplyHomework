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

	@onStop ->
		Meteor.clearInterval handle

	cursor =
		CalendarItems.find
			userIds: userId
			startDate: $gte: from
			endDate: $lte: to

	findAbsence = (calendarItemId) -> Absences.findOne { calendarItemId, userId }
	transform = (doc) ->
		doc.usersDone = (
			if userId in doc.usersDone then [ userId ]
			else []
		)
		doc

	cursor.observeChanges
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

	@ready()

Meteor.publish 'externalGrades', (options) ->
	check options, Object
	{ classId, onlyRecent } = options

	@unblock()
	unless @userId?
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
	Grades.find query

Meteor.publish 'externalStudyUtils', (classId) ->
	check classId, String

	@unblock()
	unless @userId?
		@ready()
		return undefined

	handle = Helpers.interval (=>
		updateStudyUtils @userId, no
	), 1000 * 60 * 20 # 20 minutes

	@onStop ->
		Meteor.clearInterval handle

	StudyUtils.find
		ownerId: @userId
		classId: classId
