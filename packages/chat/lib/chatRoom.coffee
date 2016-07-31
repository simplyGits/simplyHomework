###*
# @class ChatRoom
# @constructor
# @param {String} creatorId The ID of the user that created this ChatRoom.
# @param {String} type The type of chatroom.
###
class ChatRoom
	constructor: (creatorId, @type) ->
		###*
		# Array containg the users that are in this ChatRoom.
		#
		# @property users
		# @type String[]
		###
		@users = [ creatorId ]

		###*
		# @property classInfo
		# @type undefined|Object
		# @default undefined
		###
		@classInfo = undefined

		###*
		# The ID of the project this ChatRoom is for.
		#
		# @property projectId
		# @type String
		# @default undefined
		###
		@projectId = undefined

		###*
		# For group or class chats, this will be the subject of the chat.
		# This should be `undefined` if this is a 1-on-1 chat or a project chat.
		#
		# @property subject
		# @type String|undefined
		# @default undefined
		###
		@subject = undefined

		###*
		# Date of the last message.
		#
		# @property lastMessageTime
		# @type Date|undefined
		# @default undefined
		###
		@lastMessageTime = undefined

		###*
		# Array of objects describing what happend in the chat (person joined or
		# left) and when that happened.
		#
		# @property events
		# @type Object[]
		###
		@events = [{
			type: 'created'
			userId: creatorId
			time: new Date
		}]

@ChatRoom = ChatRoom
