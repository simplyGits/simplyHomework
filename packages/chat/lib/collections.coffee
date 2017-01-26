ChatRooms = new Mongo.Collection 'chatRooms', transform: (room) ->
	room = _.extend new ChatRoom, room
	chatRoomTransform?(room) ? room
ChatMessages = new Mongo.Collection 'chatMessages', transform: (m) ->
	m = _.extend new ChatMessage, m
	if Meteor.isClient
		ChatMiddlewares.run m
	else
		m

@ChatMessages = ChatMessages
@ChatRooms = ChatRooms
