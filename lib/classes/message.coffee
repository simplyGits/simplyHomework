###*
# @class Message
# @constructor
# @param {String} subject
# @param {String} body
# @param {String} folder
# @param {Date} sendDate
# @param {ExternalPerson} sender
###
class @Message
	constructor: (@subject, @body, @folder, @sendDate, @sender) ->
		@_id = new Mongo.ObjectID().toHexString()

		###*
		# @property recipients
		# @type ExternalPerson[]
		# @default []
		###
		@recipients = []

		###*
		# @property attachmentIds
		# @type String[]
		# @default []
		###
		@attachmentIds = []

		###*
		# @property fetchedFor
		# @type String[]
		# @default []
		###
		@fetchedFor = []

		###*
		# @property readBy
		# @type String[]
		# @default []
		###
		@readBy = []

		###*
		# @property fetchedBy
		# @type String|undefined
		# @default undefined
		###
		@fetchedBy = undefined

		###*
		# @property externalId
		# @type any
		# @default undefined
		###
		@externalId = undefined

		###*
		# @property notifiedOn
		# @type Date|null
		# @default null
		###
		@notifiedOn = null

	attachments: -> Files.find(_id: $in: @attachmentIds).fetch()

	# TODO: make this based on length of the res string instead of amount of
	# items since they can vary in length.
	recipientsString: (max = Infinity, html = yes) ->
		names = _(@recipients)
			.map (r) ->
				user = Meteor.users.findOne r.userId
				if user? and html
					fullName = "#{user.profile.firstName} #{user.profile.lastName}"
					path = FlowRouter.path 'personView', id: user._id
					"<a href='#{path}'>#{fullName}</a>"
				else
					r.fullName

			.take max
			.value()

		res = names.join ', '
		diff = @recipients.length - names.length
		if diff > 0
			res += " en #{diff} #{if diff is 1 then 'andere' else 'anderen'}."

		res

	@schema: new SimpleSchema
		_id:
			type: String
		subject:
			type: String
		body:
			type: String
		folder:
			type: String
			allowedValues: [ 'inbox', 'outbox' ]
		sendDate:
			type: Date
			index: -1
		sender:
			type: ExternalPerson
		recipients:
			type: [ExternalPerson]
		attachmentIds:
			type: [String]
			defaultValue: []
		fetchedFor:
			type: [String]
			index: 1
		readBy:
			type: [String]
		fetchedBy:
			type: String
			optional: yes
		externalId:
			type: null
			optional: yes
		notifiedOn:
			type: Date
			optional: yes

@Messages = new Mongo.Collection 'messages', transform: (m) -> _.extend new Message, m
# @Messages.attachSchema Message.schema

###*
# @class Draft
# @constructor
# @param {String} subject
# @param {String} body
# @param {String} senderId
###
class @Draft
	constructor: (@subject, @body, @senderId) ->
		@_id = new Mongo.ObjectID().toHexString()

		###*
		# @property lastEditTime
		# @type Date
		# @default new Date
		###
		@lastEditTime = new Date

		###*
		# @property recipients
		# @type String[]
		# @default []
		###
		@recipients = []

		###*
		# @property attachmentIds
		# @type String[]
		# @default []
		###
		@attachmentIds = []

		###*
		# @property senderService
		# @type String|undefined
		# @default undefined
		###
		@senderService = undefined

	attachments: -> Files.find(_id: $in: @attachmentIds).fetch()

	# TODO: make this based on length of the res string instead of amount of
	# items since they can vary in length.
	recipientsString: (max = Infinity) ->
		names = _.take(@recipients, max).join ', '
		diff = @recipients.length - max
		if diff > 0
			names += " en #{diff} #{if diff is 1 then 'andere' else 'anderen'}."
		names

	@schema: new SimpleSchema
		_id:
			type: String
		subject:
			type: String
		body:
			type: String
		senderId:
			type: String
			index: 1
		lastEditTime:
			type: Date
		recipients:
			type: [String]
		attachmentIds:
			type: [String]
			defaultValue: []
		senderService:
			type: String
			optional: yes

@Drafts = new Mongo.Collection 'drafts', transform: (d) -> _.extend new Draft, d
# @Drafts.attachSchema Draft.schema
