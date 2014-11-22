root = @

###*
# Chapter of a book.
#
# @class Chapter
###
class @Chapter
	constructor: (@_name, @_number) ->
		@_className = "Chapter"
		@_id = new Meteor.Collection.ObjectID()

		@_paragraphs = []

		@name = root.getset "_name", String
		@number = root.getset "_number", Number
		@paragraphs = root.getset "_paragraphs", [root.Paragraph._match], no

	@_match: (binding) ->
		return Match.test binding, Match.ObjectIncluding
				_bookId: String
				_name: String
				_number: Number