Meteor.methods
	###*
	# Marks chatMessages as read.
	# @method markChatMessagesRead
	# @param type {String} The type, possible values: "project", "direct", "group"
	# @param id {ObjectID} The ID of `type` (eg. if `type` is `"project"` then `id` is the ID of the Project).
	###
	markChatMessagesRead: (type, id) ->
		query = switch type
			when "direct"
				{
					$or: [
						{ creatorId: @userId, to: id }
						{ creatorId: id, to: @userId }
					],
					readBy: $ne: @userId
				}

			when "project"
				{
					projectId: id
					readBy: $ne: @userId
				}

		ChatMessages.update query, { $push: readBy: @userId }, multi: yes
