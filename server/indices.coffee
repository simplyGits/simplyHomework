Meteor.startup ->
	Classes._ensureIndex
		year: 1
		schoolVariant: 1
		name: 1

	Projects._ensureIndex
		participants: 1
		deadline: 1
		name: 1

	Absences._ensureIndex
		userId: 1
		calendarItemId: 1

	CalendarItems._ensureIndex
		userIds: 1
		startDate: -1
		endDate: -1

	Grades._ensureIndex
		ownerId: 1
		dateFilledIn: -1
		classId: 1
		grade: 1

	StudyUtils._ensureIndex
		userIds: 1
		classId: 1

	Messages._ensureIndex
		fetchedFor: 1
		sendDate: -1

	Meteor.users._ensureIndex
		'profile.schoolId': 1
		'profile.firstName': 1
		'profile.lastName': 1
