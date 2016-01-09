Meteor.startup ->
	loadingObserve = yes

	ChatRooms.find({}, fields: _id: 1).observe
		changed: (newDoc, oldDoc) ->
			if newDoc.users.length is 0
				ChatRooms.remove newDoc._id

		removed: (doc) ->
			# Remove the ChatMessages when the parent ChatRoom is removed.
			ChatMessages.remove chatRoomId: doc._id

	Projects.find({}, fields: _id: 1, creatorId: 1, participants: 1).observe
		added: (doc) ->
			return if loadingObserve
			# Create a new ChatRoom for a Project when one is created.
			chatRoom = new ChatRoom doc.creatorId, 'project'
			chatRoom.projectId = doc._id
			ChatRooms.insert chatRoom

		changed: (newDoc, oldDoc) ->
			if newDoc.participants.length > 0
				chatRoom = ChatRooms.findOne {
					projectId: newDoc._id
				}, {
					fields:
						_id: 1
						users: 1
				}

				newPersons = _.difference newDoc.participants, chatRoom.users
				leftPersons = _.difference chatRoom.users, newDoc.participants

				newPersonEvents = newPersons.map (id) ->
					type: 'joined'
					userId: id
					time: new Date
				leftPersonEvents = leftPersons.map (id) ->
					type: 'left'
					userId: id
					time: new Date

				ChatRooms.update chatRoom._id,
					$set: users: newDoc.participants
					$push: events: $each: newPersonEvents.concat leftPersonEvents

		removed: (doc) ->
			# Remove the ChatRoom when the linked Project is removed.
			ChatRooms.remove projectId: doc._id

	Meteor.users.find({}, fields: _id: 1).observe
		removed: (doc) ->
			ChatRooms.remove
				type: 'private'
				users: doc._id

			ChatRooms.update { users: doc._id }, $pull: users: doc._id

	loadingObserve = no
