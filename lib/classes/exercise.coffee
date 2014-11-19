root = @

class @Exercise
	constructor: (@_parent, @_paragraph, @_page) ->
		@_className = "Exercise"
		@_id = new Meteor.Collection.ObjectID()
		@_references = []

		@paragraph = root.getset "_paragraph", Paragraph._match
		@page = root.getset "_page", Number
		@references = root.getset "_references", Match.Any, no

		@addReference = root.add "_references", "Reference"
		@removeReference = root.remove "_references", "Reference"

class @Reference extends @VoteableThing
	constructor: (@_parent, @posterId, @content) ->
		@_className = "Reference"
		super @