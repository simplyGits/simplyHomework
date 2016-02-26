Meteor.publish 'usersData', (ids) ->
	@unblock()
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
			'profile.schoolId': schoolId
			'profile.firstName': $ne: ''
		}, {
			fields:
				profile: 1
				'settings.privacy.publishCalendarItems': 1
		}

		ChatRooms.find
			userIds: _.union ids, [ userId ]
	]

Meteor.publish 'status', (ids) ->
	@unblock()
	check ids, [String]
	unless @userId?
		@ready()
		return undefined

	schoolId = Meteor.users.findOne(@userId).profile.schoolId

	Meteor.users.find {
		_id: $in: ids
		'profile.schoolId': schoolId
		$or: [
			{ 'settings.privacy.publishStatus': $exists: no }
			{ 'settings.privacy.publishStatus': yes }
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
			premiumInfo: 1
			settings: 1
			profile: 1
			roles: 1
			setupProgress: 1

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

		# TODO: move this to the notices package
		Notifications.find
			userIds: userId
			done: $ne: userId
	]

Meteor.publishComposite 'classes', (options) ->
	@unblock()
	check options, Match.Optional Object

	{ hidden, all } = options ? {}
	hidden = yes # REVIEW: should this still be forced set to `true`?
	all ?= no
	check hidden, Boolean
	check all, Boolean

	unless @userId?
		@ready()
		return undefined

	find: ->
		Meteor.users.find @userId,
			fields:
				'classInfos': 1
				'profile.courseInfo': 1
	children: [{
		find: (user) ->
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
	}]

Meteor.publish 'fr_classes', ->
	unless @userId?
		@ready()
		return undefined

	classInfos = getClassInfos @userId
	Classes.find _id: $in: _.pluck classInfos, 'id'

Meteor.publishComposite 'classInfo', (classId) ->
	@unblock()
	check classId, String
	unless @userId? and classId
		@ready()
		return undefined

	find: -> Classes.find classId
	children: [{
		find: (c) ->
			# OPTIMIZE
			CalendarItems.find
				userIds: @userId
				classId: classId
				startDate: $gt: Date.today()
				endDate: $lt: Date.today().addDays 7
	}, {
		find: (c) ->
			ChatRooms.find
				type: 'class'
				users: @userId
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
				Meteor.users.find {
					_id: $in: room.users
				}, {
					fields: profile: 1
				}
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
	@unblock()
	check id, String
	find: -> Projects.find _id: id, participants: @userId
	children: [{
		find: (project) -> ChatRooms.find projectId: project._id
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

Meteor.publishComposite 'books', (classId) ->
	@unblock()
	check classId, Match.Optional String
	unless @userId?
		@ready()
		return undefined

	if classId?
		find: -> Books.find { classId }
	else
		find: ->
			Meteor.users.find @userId,
				fields:
					classInfos: 1
		children: [{
			find: (user) -> Books.find _id: $in: _.pluck user.classInfos, 'bookId'
		}]

Meteor.publish 'tests', ->
	@unblock()
	unless @userId?
		@ready()
		return undefined

	CalendarItems.find {
		'userIds': @userId
		'content': $exists: yes
		'content.type': $in: [ 'test', 'exam', 'quiz', 'oral' ]
		'content.description': $exists: yes
		'startDate': $gt: Date.today()
		'scrapped': no
	}, {
		sort:
			startDate: 1
	}

Meteor.publish 'scholieren.com', (id) ->
	@unblock()
	check id, Number
	unless @userId?
		@ready()
		return undefined
	ScholierenClasses.find { id }

Meteor.publish 'woordjesleren', (id) ->
	@unblock()
	check id, Number
	unless @userId?
		@ready()
		return undefined
	WoordjesLerenClasses.find { id }

Meteor.publish 'message', (id) ->
	@unblock()
	check id, String
	unless @userId?
		@ready()
		return undefined

	Messages.find {
		_id: id
		fetchedFor: @userId
	}, {
		limit: 1
		sort:
			sendDate: -1
	}

Meteor.publish 'messagesCount', (folder) ->
	check folder, String
	Counts.publish this, 'messagesCount', Messages.find
		fetchedFor: @userId
		folder: folder
	undefined

Meteor.publish 'files', (fileIds) ->
	@unblock()
	check fileIds, [String]
	unless @userId?
		@ready()
		return undefined

	Files.find
		_id: $in: fileIds
		userIds: @userId
