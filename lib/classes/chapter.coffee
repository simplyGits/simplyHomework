root = @

###*
# Chapter of a book.
#
# @class Chapter
###
class @Chapter
	constructor: (@_parent, @_name, @_number) ->
		@_className = "Chapter"
		@_id = new Meteor.Collection.ObjectID()

		@_paragraphs = []

		@name = root.getset "_name", String
		@number = root.getset "_number", Number
		@paragraphs = root.getset "_paragraphs", [root.Paragraph._match], no

		@addParagraph = root.add "_paragraphs", "Paragraph"
		@removeParagraph = root.remove "_paragraphs", "Paragraph"

		@dependency = new Deps.Dependency

	_setDeps: ->
		Deps.autorun (computation) => # Calls the dependency of the sender object, unless it's null
			@dependency.depend()
			@_parent.dependency.changed() if @_parent? and !computation.firstRun

	@_match: (binding) ->
		return Match.test binding, Match.ObjectIncluding
				_bookId: String
				_name: String
				_number: Number