Meteor.startup ->
	ChatMessages._ensureIndex
		chatRoomId: 1
		readBy: 1
		time: -1
		creatorId: 1

	ChatRooms._ensureIndex
		users: 1
		type: 1
		projectId: 1
		lastMessageTime: 1
		subject: 1
