root = @

class @Exercise
	constructor: (@_parent, @_paragraph, @_page) ->
		@_className = "Exercise"
		@_id = new Meteor.Collection.ObjectID()
		@_references = []
		@_referencesDependency = new Deps.Dependency

		@dependency = new Deps.Dependency

		@paragraph = root.getset "_paragraph", Paragraph._match
		@page = root.getset "_page", Number
		@references = root.getset "_references", Match.Any, no

		@addReference = root.add "_references", "Reference"
		@removeReference = root.remove "_references", "Reference"

		Deps.autorun (computation) =>
			@_referencesDependency.depend()
			@dependency.changed() if !computation.firstRun

	_setDeps: ->
		Deps.autorun (computation) => # Calls the dependency of the sender object, unless it's null
			@dependency.depend()
			@_parent.dependency.changed() if @_parent? and !computation.firstRun

	@_match: (exercise) ->
		return Match.test exercise, Match.ObjectIncluding
				_paragraph: Paragraph._match
				_page = Number

class @Reference extends @VoteableThing
	constructor: (@_parent, @posterId, @content) ->
		@_className = "Reference"
		@dependency = new Deps.Dependency

		Deps.autorun (computation) => # Calls the dependency of the sender object, unless it's null
			@dependency.depend()
			@_parent.dependency.changed() if @_parent? and !computation.firstRun

		super @