###*
# Repesents a school.
#
# @class School
###
class @School
	###*
	# Constructor for the current School
	#
	# @method constructor
	# @param name {String} The name of the school
	# @param [url] {String} The URL of the school.
	###
	constructor: (@name, @url) ->
		@externalInfo = {}

	###*
	# Return a cursor pointing to the books that this school uses.
	#
	# @method books
	# @return {Cursor} Cursor pointing to the books this school uses.
	###
	getBooks: -> Books.find { _id: { $in: @_books }}

	###*
	# Return a cursor pointing to the users that that are pupils of this school.
	#
	# @method users
	# @return {Cursor} A cursor pointing to the users that are pupils of this school.
	###
	users: -> Meteor.users.find "profile.schoolId": @_id

	getUtils: -> Utils.find { _id: { $in: @_utils }}
