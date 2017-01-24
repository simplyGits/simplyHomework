projectTransform = (p) ->
	p = _.extend new Project, p
	_.extend p,
		__borderColor: (
			now = new Date
			if p.deadline?
				switch
					when p.deadline < now then '#FF4136'
					when Helpers.daysRange(now, p.deadline, no) < 2 then '#FF8D00'
					else '#2ECC40'
			else
				'#000'
		)
		__friendlyDeadline: (
			if p.deadline?
				Helpers.cap Helpers.formatDateRelative p.deadline, yes
		)
		__lastChatMessage: ->
			chatRoom = @getChatRoom()
			if chatRoom?
				ChatMessages.findOne {
					chatRoomId: chatRoom._id
				}, sort:
					'time': -1

###*
# A project that can be worked on with multiple persons.
# @class Project
# @constructor
# @param name {String} The name of the project. Manually entered or copied from Magister.
# @param [description] {String} The desctiption of the project. Manually entered or copied from Magister.
# @param deadline {Date} The time this project has to be finished.
# @param creatorId {String} The ID of the creator of this project.
# @param [classId] {String} The ID of the class for this project.
###
class @Project
	constructor: (@name, @description, @deadline, @creatorId, @classId) ->
		###*
		# @property creationDate
		# @type Date
		# @default new Date()
		###
		@creationDate = new Date()

		###*
		# The IDs of the participants of this project.
		# @property participants
		# @type String[]
		# @default [ @creatorId ]
		###
		@participants = [ @creatorId ]

		###*
		# The IDs of Google Drive files that are in this project.
		# @property driveFileIds
		# @type String[]
		# @default []
		###
		@driveFileIds = []

		###*
		# The assignment object this Project is coupled with, if any.
		# This should be kept up-to-date with the version provided by the
		# externalService that provided this assignment object.
		#
		# @property assignment
		# @type Assignment
		# @default undefined
		###
		@assignment = undefined

		###*
		# @property finished
		# @type Boolean
		# @default false
		###
		@finished = no

	###*
	# @method getClass
	# @return {SchoolClass}
	###
	getClass: -> Classes.findOne @classId

	###*
	# @method getChatRoom
	# @return {ChatRoom}
	###
	getChatRoom: -> ChatRooms.findOne projectId: @_id

	@schema: new SimpleSchema
		name:
			type: String
			autoValue: ->
				# Remove emojis.
				@value.replace /[\uD83C-\uDBFF\uDC00-\uDFFF]+/g, '' if @value?
		description:
			type: String
			optional: yes
		deadline:
			type: Date
		creatorId:
			type: String
			denyUpdate: yes
			autoValue: -> if not @isFromTrustedCode and @isInsert then @userId else @value
		classId:
			type: String
			optional: yes
		creationDate:
			type: Date
			denyUpdate: yes
		participants:
			type: [String]
			autoValue: ->
				if not @isFromTrustedCode and @isInsert
					[@userId]
				else @value
		driveFileIds:
			type: [String]
		finished:
			type: Boolean
			autoValue: ->
				if not @isFromTrustedCode and @isInsert then no
				else @value

@Projects = new Mongo.Collection 'projects', transform: (p) -> projectTransform p
@Projects.attachSchema Project.schema
