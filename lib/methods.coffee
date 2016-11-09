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

		book = Books.findOne { title, classId }
		if book?
			book._id
		else
			book = new Book title, classId

			containsTitle = (str) -> Helpers.contains str, title, yes
			for [ service, coll ] in _.pairs(
				woordjesleren: WoordjesLerenClasses
				scholieren: ScholierenClasses
			)
				if c.externalInfo[service]?
					serviceBooks = coll.findOne(id: c.externalInfo[service].id).books
					serviceBook = _.find serviceBooks, (b) -> containsTitle b.title

					if serviceBook?
						book.externalInfo[service] = serviceBook.id

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

	###*
	# @method addProjectParticipant
	# @param {String} projectId
	# @param {String} userId
	###
	addProjectParticipant: (projectId, userId) ->
		check projectId, String
		check userId, String

		p = Projects.findOne projectId

		unless p?
			throw new Meteor.Error 'not-found'
		if @userId not in p.participants
			throw new Meteor.Error 'unauthorized'
		if userId in p.participants
			return

		Projects.update projectId, $push: participants: userId
		Meteor.defer => NoticeMails?.projects projectId, userId, @userId

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
			$set: isRead: yes
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
		lastName = Helpers.nameCap lastName.trim()

		if firstName.length is 0 or lastName.length is 0
			throw new Meteor.Error 'name-empty'

		Meteor.users.update @userId,
			$set:
				'profile.firstName': firstName
				'profile.lastName': lastName

	###*
	# @method saveMessageDraft
	# @param {Draft} draft
	###
	saveMessageDraft: (draft) ->
		check draft, Object
		fieldEmpty = (key) ->
			val = draft[key]
			val = val.trim() if _.isString val
			val.length is 0

		if _.all [ 'subject', 'body', 'recipients' ], fieldEmpty
			Drafts.remove
				_id: draft._id
				senderId: @userId
		else
			prevDraft = Drafts.findOne draft._id
			if prevDraft?
				if prevDraft.senderId isnt @userId
					throw new Meteor.Error 'not-owner'
				else
					Drafts.update draft._id, draft
			else
				Drafts.insert draft

		undefined

###*
# @method genClassInfoChangeFunc
# @param {String} field
# @param {Function} type
# @return {Function}
###
genClassInfoChangeFunc = (field, type) ->
	(classId, val) ->
		check classId, String
		check val, type

		classInfo = _.find getClassInfos(@userId), id: classId
		unless classInfo[field] is val
			Meteor.users.update @userId, $pull:
				classInfos: id: classId
			Meteor.users.update @userId, $push:
				classInfos: _.extend classInfo, "#{field}": val

		undefined

Meteor.methods
	###*
	# @method setClassHidden
	# @param {String} classId
	# @param {Boolean} hidden
	###
	setClassHidden: genClassInfoChangeFunc 'hidden', Boolean

	###*
	# @method setClassBookId
	# @param {String} classId
	# @param {Boolean} bookId
	###
	setClassBookId: genClassInfoChangeFunc 'bookId', String
