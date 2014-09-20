root = @

###*
# A service ticket.
#
# @class Ticket
###
class @Ticket
	constructor: (@_sender, @_victim, @_helper, @_description, @_isHelped) ->
		@_className = "Ticket"
		@_id = new Meteor.Collection.ObjectID()

		@victim = root.getset "_victim", String # userID
		@helper = root.getset "_helper", String
		@description = root.getset "_description", String
		@isHelped = root.getset "_isHelped", Boolean

		@dependency = new Deps.Dependency

	_setDeps: ->
		Deps.autorun (computation) => # Calls the dependency of the sender object, unless it's null
			@dependency.depend()
			@_parent.dependency.changed() if @_parent? and !computation.firstRun

	@_match: (ticket) ->
		return Match.test ticket, Match.ObjectIncluding
				_victim: String
				_helper: String
				_description: String
				_isHelped: Boolean