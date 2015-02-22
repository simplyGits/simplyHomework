###*
# A ChatMessage. Can be linked to a Project or between users.
# ChatMessages support (GitHub) Markdown styled bodies.
#
# @class ChatMessage
# @constructor
# @param content {String} The content (/ body) of the message.
# @param creatorId {String} The ID of the person that created this message.
###
class @ChatMessage
	constructor: (@content, @creatorId = Meteor.userId(), @to) ->
		@_id = new Meteor.Collection.ObjectID()

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
		# The ID of the project this Message is part of.
		#
		# @property projectId
		# @type String
		###
		@projectId = null

		###*
		# The ID of the group which can read this message.
		#
		# @property groupId
		# @type String
		###
		@groupId = null

		###*
		# The ID of the person that this message is sent to.
		# This is ignored when a projectId or groupId is set.
		#
		# @property to
		# @type String
		# @default ""
		###
		@to ?= ""

		###*
		# The IDs of the persons that read this message.
		#
		# @property readBy
		# @type String[]
		###
		@readBy = []

		###*
		# Attachments as base64 encoded String(s).
		#
		# @property attachments
		# @type String[]
		# @default []
		###
		@attachments = []

		###*
		# True if the contents of this message has been changed since the original insert.
		#
		# @property isChanged
		# @type Boolean
		# @default []
		###
		@isChanged = no
