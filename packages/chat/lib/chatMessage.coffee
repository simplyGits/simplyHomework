###*
# A ChatMessage. Can be linked to a Project or between users.
# ChatMessages support (GitHub) Markdown styled bodies.
#
# @class ChatMessage
# @constructor
# @param {String} content The content (/ body) of the message.
# @param {String} creatorId The ID of the person that created this message.
# @param {String} chatRoomId The ID of the ChatRoom this ChatMessage is sent in.
###
class ChatMessage
	constructor: (@content, @creatorId = Meteor.userId(), @chatRoomId) ->
		###*
		# The body of the Message.
		# (GitHub) Markdown styled.
		#
		# @property content
		# @type String
		# @default ""
		###
		@content ?= ""

		###*
		# The date the Message was created.
		#
		# @property time
		# @type Date
		# @final
		# @default new Date()
		###
		@time = new Date()

		###*
		# The IDs of the persons that read this message.
		#
		# @property readBy
		# @type String[]
		# @default [ this.creatorId ]
		###
		@readBy = [ @creatorId ]

		###*
		# Attachments as base64 encoded String(s).
		#
		# @property attachments
		# @type String[]
		# @default []
		###
		@attachments = []

		###*
		# The date the content of this message was changed since the original insert.
		# If null the content is still the same.
		#
		# @property changedOn
		# @type Date|null
		# @default null
		###
		@changedOn = null

@ChatMessage = ChatMessage
