root = @

###*
# A location
# Currently not reactive, we will see how it goes.
#
# @class Location
###
class @Location
	constructor: (@_parent) ->
		@_className = "Location"
		@_location = ""

		@longitude = root.getset "_longitude", Number
		@latitude = root.getset "_latitude", Number
		@location = root.getset "_location", String

		@dependency = new Deps.Dependency()

	_setDeps: ->
		Deps.autorun (computation) => # Calls the dependency of the sender object, unless it's null
			@dependency.depend()
			@_parent.dependency.changed() if @_parent? and !computation.firstRun

	@_match: (location) ->
		return Match.test location, Match.OneOf(
			Match.ObjectIncluding(
					longitude: Number
					latitude: Number
					
			), Match.ObjectIncluding(
					location: String
			))