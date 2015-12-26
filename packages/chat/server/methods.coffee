Meteor.methods
	markTyping: (chatRoomId, typing) ->
		check chatRoomId, String
		check typing, Boolean

		userId = @userId
		room = ChatRooms.findOne
			_id: chatRoomId
			users: userId

		unless room?
			throw new Meteor.Error 'not-in-room'

		Streamy.sessionsForUsers(room.users).emit 'typing',
			chatRoomId: chatRoomId
			user: userId
			typing: typing

		undefined
