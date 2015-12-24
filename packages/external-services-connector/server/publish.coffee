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
		updateCalendarItems @userId, from, to
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
