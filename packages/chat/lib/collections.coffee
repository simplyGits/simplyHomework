ChatRooms = new Meteor.Collection 'chatRooms', transform: (c) -> chatRoomTransform?(c) ? c
ChatMessages = new Meteor.Collection 'chatMessages', transform: (m) -> ChatMiddlewares.run m

@ChatMessages = ChatMessages
@ChatRooms = ChatRooms
