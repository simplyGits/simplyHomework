###*
# @class Message
# @constructor
# @param {String} subject
# @param {String} body
# @param {String} folder
# @param {Date} sendDate
# @apram {Object} sender
###
class @Message
	constructor: (@subject, @body, @folder, @sendDate, @sender) ->
		###*
		# @property recipients
		# @type Object[]
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
		subject:
			type: String
		body:
			type: String
		folder:
			type: String
			allowedValues: [ 'inbox', 'alerts', 'outbox' ]
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
		readBy:
			type: [String]
		fetchedBy:
			type: String
			optional: yes
		externalId:
			type: null
			optional: yes

@Messages = new Mongo.Collection 'messages', transform: (m) -> _.extend new Message, m
# @Messages.attachSchema Message.schema
