###*
# Class to repesent a book / 'methode'
#
# @class Book
###
class @Book
	###*
	# Constructor of the Book class.
	#
	# @method constructor
	# @param title {String} The title of the book.
	# @param publisher {String} The publisher of the book.
	# @param woordjesLerenBookId {Number} The ID used on Woordjesleren.nl
	# @param release {Number} The 'version' of the book.
	# @param classId {Object} The ID of the Class this Book is part of.
	###
	constructor: (@title, @publisher, @woordjesLerenBookId, @release, @classId) ->
		@_id = new Meteor.Collection.ObjectID()

		@utils = [] # utils by ID
		@chapters = []