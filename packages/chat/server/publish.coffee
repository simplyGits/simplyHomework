# Let's hope that this package is performant.
Meteor.publishComposite 'basicChatInfo',
	find: -> ChatRooms.find users: @userId
	children: [{
		find: (room) ->
			ChatMessages.find {
				chatRoomId: room._id
				creatorId: $ne: @userId
				readBy: $ne: @userId
			}, sort:
				'time': -1
	}, {
		find: (room) ->
			Meteor.users.find {
				_id: $in: _.reject room.users, @userId
			}, fields:
				'profile.pictureInfo': 1
				'profile.firstName': 1
				'profile.lastName': 1
				'status.online': 1
				'status.idle': 1
	}, {
		find: (room) ->
			Projects.find {
				_id: room.projectId
			}, fields:
				name: 1
	}]

Meteor.publish 'chatMessages', (chatRoomId, limit) ->
	check chatRoomId, String
	check limit, Number

	unless @userId
		@ready()
		return undefined

	console.log @userId, chatRoomId, limit

	room = ChatRooms.findOne
		_id: chatRoomId
		users: @userId

	unless room?
		@ready()
		return undefined

	# Makes sure we're getting a number in a base of of 10. This is so that we
	# minimize the amount of unique cursors in the mergebox.
	# This shouldn't be needed since the client only increments the limit by ten,
	# but we want to make sure it is server side too.
	limit = limit + 9 - (limit - 1) % 10

	cursor =
		ChatMessages.find {
			chatRoomId
		}, {
			limit: limit
			sort: 'time': -1
		}

	handle = cursor.observeChanges
		added: (id, record) =>
			@added 'chatMessages', id, record

		changed: (id, record) =>
			@changed 'chatMessages', id, record

		###
		removed: (id) =>
			@removed 'chatMessages', id
		###

	@ready()
	@onStop ->
		handle.stop()

Meteor.publish 'messageCount', (chatRoomId) ->
	# TODO: secure this method.
	check chatRoomId, String
	Counts.publish this, 'chatMessageCount', ChatMessages.find { chatRoomId }
	undefined
