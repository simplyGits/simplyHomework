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