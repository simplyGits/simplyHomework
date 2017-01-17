# REVIEW: do we want to support externalFiles?

###*
# @class ServiceUpdate
# @constructor
# @param {String} header
# @param {String} body
# @param {String} userId
# @param {String} fetchedBy
# @param {String} externalId
###
class @ServiceUpdate
	constructor: (@header, @body, @userId, @fetchedBy, @externalId) ->
		@_id = new Mongo.ObjectID().toHexString()

		###*
		# @property date
		# @type Date|undefined
		# @default undefined
		###
		@date = undefined

		###*
		# @property priority
		# @type Number
		# @default 0
		###
		@priority = 0

	@schema: new SimpleSchema
		_id:
			type: String
		header:
			type: String
		body:
			type: String
			defaultValue: ''
		userId:
			type: String
		fetchedBy:
			type: String
		externalId:
			type: null
		date:
			type: Date
			optional: yes
		priority:
			type: Number

@ServiceUpdates = new Mongo.Collection 'serviceUpdates'
@ServiceUpdates.attachSchema ServiceUpdate.schema
