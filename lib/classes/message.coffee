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
		# @property attachments
		# @type ExternalFile[]
		# @default []
		###
		@attachments = []

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

class @MessageRecipient
	constructor: (@firstName = '', @lastName = '') ->
		@userId = undefined

		@fullName = ''

		@teacherCode = undefined
