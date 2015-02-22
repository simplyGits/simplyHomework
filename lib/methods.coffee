Meteor.methods
	markChatMessagesRead: (query) -> ChatMessages.update query, { $push: readBy: Meteor.userId() }, multi: yes
