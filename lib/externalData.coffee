@getGradesCursor = (query, userId = Meteor.userId()) ->
	if Meteor.isClient and userId isnt Meteor.userId()
		throw new Error 'Client code can only fetch their own grades.'

	Meteor.call 'updateGrades', userId, no, yes

	StoredGrades.find query

@getStudyUtilsCursor = (query, userId = Meteor.userId()) ->
	if Meteor.isClient and userId isnt Meteor.userId()
		throw new Error 'Client code can only fetch their own utils.'

	Meteor.call 'updateStudyUtils', userId, no, yes

	StudyUtils.find query

@getCalendarItems = (query, userId = Meteor.userId()) ->
	if Meteor.isClient and userId isnt Meteor.userId()
		throw new Error 'Client code can only fetch their own calendarItems.'

	Meteor.call 'updateCalendarItems', userId, no, yes

	CalendarItems.find query

@getPersons = (query, type, userId = Meteor.userId()) ->
	callback = _.last arguments
	if Meteor.isClient and not _.isFunction(callback)
		throw new Error 'Callback required on client.'

	if Meteor.isClient and userId isnt Meteor.userId()
		throw new Error 'Client code can only fetch persons using their own account.'

	trans = (arr) -> (_.extend(new ExternalPerson, p) for p in arr)

	res = Meteor.call(
		'getPersons',
		query,
		type,
		userId,
		if callback? then (e, r) -> callback e, (trans r if r?)
	)
	trans res if res?
