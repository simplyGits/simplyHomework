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
	# @param scholierenBookId {Number} The ID used on Scholieren.com.
	# @param release {Number} The 'version' of the book.
	# @param classId {Object} The ID of the Class this Book is part of.
	###
	constructor: (@title, @publisher, @scholierenBookId, @release, @classId) ->
		@_id = new Meteor.Collection.ObjectID()

		@utils = [] # utils by ID
		@chapters = []
