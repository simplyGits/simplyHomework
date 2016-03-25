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
	# Creates and inserts a book.
	# @method insertBook
	# @param {String} title
	# @param {String} classId
	# @return {String} The id of the newely inserted book.
	###
	insertBook: (title, classId) ->
		check title, String
		check classId, String

		if Helpers.isEmptyString title
			throw new Meteor.Error 'empty-title'

		c = Classes.findOne classId
		unless c?
			throw new Meteor.Error 'non-existing-class'

		book = Books.findOne title: title
		if book?
			book._id
		else
			book = new Book title, classId

			containsTitle = (str) -> Helpers.contains str, title, yes
			if c.externalInfo['woordjesleren']?
				wlbooks = WoordjesLerenClasses.findOne(
					id: c.externalInfo['woordjesleren'].id
				).books
				wlbook = _.find wlbooks, (b) -> containsTitle b.title

				if wlbook?
					book.externalInfo['woordjesleren'] = wlbook.id

			if c.externalInfo['scholieren']?
				slbooks = ScholierenClasses.findOne(
					id: c.externalInfo['scholieren'].id
				).books
				slbook = _.find slbooks, (b) -> containsTitle b.title

				if slbook?
					book.externalInfo['scholieren'] = slbook.id

			Books.insert book

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

	markMessageRead: (id) ->
		check id, String
		Messages.update {
			_id: id
			fetchedFor: @userId
		}, {
			$addToSet: readBy: @userId
		}

	###*
	# @method changeName
	# @param {String} firstName non empty string.
	# @param {String} lastName non empty string.
	###
	changeName: (firstName, lastName) ->
		check firstName, String
		check lastName, String

		firstName = firstName.trim()
		lastName = lastName.trim()

		if firstName.length is 0 or lastName.length is 0
			throw new Meteor.Error 'name-empty'

		Meteor.users.update @userId,
			$set:
				'profile.firstName': firstName
				'profile.lastName': firstName
