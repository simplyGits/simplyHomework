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
	# @param class {SchoolClass} The class this book is part of.
	# @param title {String} The title of the book.
	# @param publisher {String} The publisher of the book.
	# @param woordjesLerenBookId {Number} The ID used on Woordjesleren.nl
	# @param release {Number} The 'version' of the book.
	###
	constructor: (@class, @title, @publisher, @woordjesLerenBookId, @release) ->
		@_id = new Meteor.Collection.ObjectID()

		@utils = [] # utils by ID
		@chapters = []