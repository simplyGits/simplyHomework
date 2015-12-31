###*
# Class to repesent a book / 'methode'
#
# @class Book
# @constructor
# @param {String} title
# @param {String} publisher
# @param {Number} release The 'version' of the book.
# @param {Object} classId The ID of the Class this Book is part of.
###
class @Book
	constructor: (@title, @publisher, @release, @classId) ->
		###*
		# @property utils
		# @type [String]
		# @default []
		###
		@utils = []

		###*
		# @property externalInfo
		# @type Object
		# @default {}
		###
		@externalInfo = {}
