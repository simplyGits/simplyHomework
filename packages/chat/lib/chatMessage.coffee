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
	constructor: (@content, @creatorId, @chatRoomId) ->
		###*
		# The body of the Message in Markdown.
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
		# The IDs of the users that has read this message.
		#
		# @property readBy
		# @type String[]
		# @default [ this.creatorId ]
		###
		@readBy = [ @creatorId ]

		###*
		# Attachments as base64 encoded Strings.
		#
		# @property attachments
		# @type String[]
		# @default []
		###
		@attachments = []

		###*
		# {
		# 	date: The date of the changes
		# 	old: The content before the change
		# 	new: The content after the change
		# }
		# @property changes
		# @type Object[]
		# @default[]
		###
		@changes = []

	lastChange: -> _.last @changes

@ChatMessage = ChatMessage
