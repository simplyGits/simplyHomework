Meteor.publish 'usersData', (ids) ->
	check ids, Match.Optional [String]
	userId = @userId
	# `if ids?` is needed to not create an array when ids is undefined, which is
	# used to get every person.
	ids = _.without ids, userId if ids?
	schoolId = Meteor.users.findOne(userId).profile.schoolId

	# We don't have to handle shit if we are only asked for the current user, no
	# users at all or the current user doesn't have a school.
	if not schoolId? or (ids? and ids.length is 0)
		@ready()
		return undefined

	[
		Meteor.users.find {
			_id: (
				if ids? then { $in: ids }
				else { $ne: userId }
			)
			#'profile.schoolId': schoolId
			'profile.firstName': $ne: ''
		}, fields: profile: 1

		ChatRooms.find
			userIds: _.union ids, [ userId ]
	]

Meteor.publish 'status', (ids) ->
	check ids, [String]
	unless @userId?
		@ready()
		return undefined

	Meteor.users.find {
		_id: $in: ids
		$or: [
			'settings.privacy.publishStatus': $exists: no
			'settings.privacy.publishStatus': yes
		]
	}, {
		fields:
			'status.online': 1
			'status.idle': 1
	}

Meteor.publish null, ->
	unless @userId?
		@ready()
		return undefined

	userId = @userId
	user = Meteor.users.findOne userId, fields: profile: 1

	[
		Meteor.users.find userId, fields:
			classInfos: 1
			createdAt: 1
			events: 1
			gradeNotificationDismissTime: 1
			magisterCredentials: 1
			plannerPrefs: 1
			premiumInfo: 1
			settings: 1
			profile: 1
			roles: 1
			setupProgress: 1
			#studyGuidesHashes: 1

		Schools.find { _id: user.profile.schoolId }, fields:
			externalInfo: 0

		Projects.find {
			participants: userId
			finished: no
		}, fields:
			name: 1
			magisterId: 1
			finished: 1
			classId: 1
			deadline: 1
			participants: 1

		Notifications.find
			userIds: userId
			done: $ne: userId
	]

Meteor.publish 'classes', (options) ->
	check options, Match.Optional Object

	{ hidden, all } = options ? {}
	hidden ?= no
	all ?= no
	check hidden, Boolean
	check all, Boolean

	unless @userId?
		@ready()
		return undefined

	user = Meteor.users.findOne @userId,
		fields:
			'classInfos': 1
			'profile.courseInfo': 1

	classInfos = user.classInfos ? []
	nonhidden = _.reject classInfos, 'hidden'
	courseInfo = user.profile.courseInfo

	# TODO: add fields filter?
	Classes.find (
		if all
			if courseInfo?
				{ year, schoolVariant } = courseInfo
				{ schoolVariant, year }
			else {}

		else if hidden then { _id: $in: _.pluck classInfos, 'id' }
		else { _id: $in: _.pluck nonhidden, 'id' }
	)

Meteor.publishComposite 'classInfo', (classId) ->
	check classId, String
	unless @userId? and classId
		@ready()
		return undefined

	find: -> Classes.find classId
	children: [{
		find: (c) ->
			# OPTIMIZE
			CalendarItems.find {
				userIds: @userId
				classId: classId
				startDate: $gt: Date.today()
				endDate: $lt: Date.today().addDays 7

				# TODO: If we change it back to 'uur/week' in classView.html this line
				# should be removed.
				scrapped: no
			}, {
				fields:
					_id: 1
					classId: 1
					start: 1
					endDate: 1
		}
	}, {
		find: (c) ->
			ChatRooms.find
				type: 'class'
				'classInfo.ids': c._id
		children: [{
			find: (room) ->
				ChatMessages.find {
					chatRoomId: room._id
				}, {
					limit: 1
					sort:
						time: -1
				}
		}, {
			find: (room) ->
				Meteor.users.find _id: $in: room.users
		}]
	}]

Meteor.publish 'schools', (externalId) ->
	check externalId, Match.Any

	if externalId?
		Schools.find { externalId }, fields: externalId: 1
	else
		Schools.find {}, fields: name: 1

Meteor.publish "goaledSchedules", -> GoaledSchedules.find { ownerId: @userId }

Meteor.publishComposite 'project', (id) ->
	check id, Mongo.ObjectID
	find: -> Projects.find _id: id, participants: @userId
	children: [{
		find: (project) -> ChatRooms.findOne projectId: id
		children: [{
			find: (room) ->
				# Just the last message to show on the projectView.
				ChatMessages.find {
					chatRoomId: room._id
				},
					limit: 1
					sort: 'time': -1
		}]
	}]

Meteor.publish "books", (classId) ->
	check classId, String
	unless @userId?
		@ready()
		return undefined

	if classId?
		Books.find { classId }
	else
		classInfos = getClassInfos @userId
		Books.find _id: $in: _.pluck classInfos, 'bookId'

Meteor.publish 'foreignCalendarItems', (userId, from, to) ->
	check userId, String
	check from, Date
	check to, Date
	unless @userId?
		@ready()
		return undefined

	user = Meteor.users.findOne userId
	unless Privacy.getOptions(userId).publishCalendarItems
		@ready()
		return undefined

	from ?= new Date().addDays -7
	to ?= new Date().addDays 7

	CalendarItems.find
		userIds: userId
		startDate: $gte: from
		endDate: $lte: to

# TODO: remove this when new homepage is up?
Meteor.publish 'userCount', ->
	Counts.publish this, 'userCount', Meteor.users.find {}
	undefined

# OPTIMIZE

Meteor.publish 'scholieren.com', ->
	unless @userId?
		@ready()
		return undefined
	ScholierenClasses.find()

Meteor.publish 'woordjesleren', ->
	unless @userId?
		@ready()
		return undefined
	WoordjesLerenClasses.find()
