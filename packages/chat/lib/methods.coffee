Meteor.methods
	###*
	# @method createPrivateChatRoom
	# @param {String} userId
	# @return {String} The ID of the newely created ChatRoom.
	###
	createPrivateChatRoom: (userId) ->
		check userId, String

		if userId is @userId
			throw new Meteor.Error 'same-person', "Can't create a chatroom with yourself."

		room = ChatRooms.findOne
			type: 'private'
			users: [ @userId, userId ]

		if room? then room._id
		else
			chatRoom = new ChatRoom @userId, 'private'
			chatRoom.users.push userId
			ChatRooms.insert chatRoom

	###*
	# @method addChatMessage
	# @param {String} content
	# @param {String} chatRoomId
	# @return {String} The ID of the added chatMessage.
	###
	addChatMessage: (content, chatRoomId) ->
		@unblock()
		check content, String
		check chatRoomId, String

		content = content.trim()
		if content.length is 0
			throw new Meteor.Error 'message-empty'

		if ChatRooms.find(_id: chatRoomId, users: @userId).count() is 0
			throw new Meteor.Error 'not-in-room'

		message = new ChatMessage content, @userId, chatRoomId
		message = ChatMiddlewares.run message, 'insert'
		if @isSimulation
			ga 'send', 'event', 'chat', 'send'
			message.pending = yes

		ChatRooms.update chatRoomId, $set: lastMessageTime: new Date
		ChatMessages.insert message

	# TODO: rerun serverside ChatMiddlewares
	###*
	# @method updateChatMessage
	# @param {String} content
	# @param {String} chatMessageId
	###
	updateChatMessage: (content, chatMessageId) ->
		@unblock()
		check content, String
		check chatMessageId, String

		content = content.trim()
		if content.length is 0
			throw new Meteor.Error 'message-empty'

		old = ChatMessages.findOne
			_id: chatMessageId
			creatorId: @userId
		if not old?
			throw new Meteor.Error 'invalid-id'
		else if old.content is content
			throw new Meteor.Error 'same-content'

		if @isSimulation
			ga 'send', 'event', 'chat', 'update'
			pending = yes

		ChatMessages.update chatMessageId,
			$set:
				content: content
				pending: pending
			$push:
				changes:
					date: new Date()
					old: old.content
					new: content
		undefined

	###*
	# Marks unread ChatMessages as read.
	# @method markChatMessagesRead
	# @param {String} chatRoomid The ID of the ChatRoom.
	###
	markChatMessagesRead: (chatRoomId) ->
		@unblock()
		check chatRoomId, String

		ChatMessages.update {
			chatRoomId: chatRoomId
			readBy: $ne: @userId
		}, {
			$push: readBy: @userId
		}, {
			multi: yes
		}
