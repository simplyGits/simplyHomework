root = @

###*
# Binding between Magister objects and simplyHomework objects.
#
# @class MagisterBinding
###
class @MagisterBinding
	constructor: (@_parent, @_homeworkId, @_assignmentId) ->
		@_className = "MagisterBinding"
		@_id = new Meteor.Collection.ObjectID()

		@homeworkId = root.getset "_homeworkId", String
		@assignmentId = root.getset "_assignmentId", String

		@dependency = new Deps.Dependency

	_setDeps: ->
		Deps.autorun (computation) => # Calls the dependency of the sender object, unless it's null
			@dependency.depend()
			@_parent.dependency.changed() if @_parent? and !computation.firstRun

	@_match: (binding) ->
		return Match.test binding, Match.ObjectIncluding
				_homeworkId: String
				_assignmentId: String