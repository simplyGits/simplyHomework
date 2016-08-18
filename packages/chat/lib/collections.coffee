ChatRooms = new Mongo.Collection 'chatRooms', transform: (room) ->
	room = _.extend new ChatRoom, room
	chatRoomTransform?(room) ? room
ChatMessages = new Mongo.Collection 'chatMessages', transform: (m) -> ChatMiddlewares.run m

@ChatMessages = ChatMessages
@ChatRooms = ChatRooms
