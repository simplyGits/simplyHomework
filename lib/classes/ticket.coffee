###*
# @class Ticket
# @constructor
# @param {String} body
# @param {String} reporterId
###
class @Ticket
	constructor: (@body, @reporterId) ->
		###*
		# @property resolvedBy
		# @type String|undefined
		# @default undefined
		###
		@resolvedBy = undefined

		###*
		# @property creationDate
		# @type Date
		# @default new Date()
		###
		@creationDate = new Date

@Tickets = new Mongo.Collection 'tickets'
