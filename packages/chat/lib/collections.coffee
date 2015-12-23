ChatRooms = new Mongo.Collection 'chatRooms', transform: (c) -> chatRoomTransform?(c) ? c
ChatMessages = new Mongo.Collection 'chatMessages', transform: (m) -> ChatMiddlewares.run m

@ChatMessages = ChatMessages
@ChatRooms = ChatRooms
