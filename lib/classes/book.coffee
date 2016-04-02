###*
# Class to repesent a book / 'methode'
#
# @class Book
# @constructor
# @param {String} title
# @param {Object} classId The ID of the Class this Book is part of.
###
class @Book
	constructor: (@title, @classId) ->
		###*
		# @property utils
		# @type [String]
		# @default []
		###
		@utils = []

		###*
		# @property publisher
		# @type String|undefined
		# @default undefined
		###
		@publisher = undefined

		###*
		# @property release
		# @type Number|undefined
		# @default undefined
		###
		@release = undefined

		###*
		# @property externalInfo
		# @type Object
		# @default {}
		###
		@externalInfo = {}

	@schema: new SimpleSchema
		title:
			type: String
		classId:
			type: String
		publisher:
			type: String
			optional: yes
		release:
			type: Number
			optional: yes
		utils:
			type: [Object]
			blackbox: yes
		externalInfo:
			type: Object
			blackbox: yes

@Books = new Mongo.Collection 'books'
@Books.attachSchema Book.schema
