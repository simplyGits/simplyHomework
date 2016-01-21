Meteor.methods
	markNotificationRead: (id, clicked) ->
		check id, String
		check clicked, Boolean

		push = {}
		push['done'] = @userId
		push['clicked'] = @userId if clicked
		Notifications.update id, $push: push

	markUserEvent: (name) ->
		check name, String
		Meteor.users.update @userId, $set: "events.#{name}": new Date
		undefined

	###*
	# @method insertClass
	# @param {String} name
	# @param {String} course
	# @return {String} The id of the newely inserted class.
	###
	insertClass: (name, course) ->
		check name, String
		check course, String

		{ year, schoolVariant } = getCourseInfo @userId
		insertClass new SchoolClass(
			name
			course
			year
			schoolVariant
		)

	###*
	# @method insertBook
	# @param {String} title
	# @param {String} classId
	# @return {String} The id of the newely inserted book.
	###
	insertBook: (title, classId) ->
		check title, String
		check classId, String

		if title.trim().length is 0
			throw new Meteor.Error 'empty-title'

		book = Books.findOne title: title
		if book?
			book._id
		else
			Books.insert new Book(
				title
				undefined
				undefined
				classId
			)

	insertProject: (name, description, deadline, classId) ->
		check name, String
		check description, String
		check deadline, Date
		check classId, Match.Optional String

		name = name.trim()

		if name.length is 0
			throw new Meteor.Error 'name-empty'

		userId = @userId
		if Projects.find({ name, participants: userId }).count() > 0
			throw new Meteor.Error 'project-exists'

		project = new Project(
			name
			description
			deadline
			userId
			classId
		)
		Projects.insert project

	markCalendarItemDone: (id, done) ->
		check id, String
		check done, Boolean

		userId = @userId

		update = (mod) -> CalendarItems.update { _id: id, userIds: userId }, mod
		if done
			update $addToSet: usersDone: userId
		else
			update $pull: usersDone: userId
