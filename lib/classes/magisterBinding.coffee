root = @

###*
# Binding between Magister objects and simplyHomework objects.
#
# @class MagisterBinding
# @param [_homeworkId] The username of the user to login to.
# @param [_assignmentId] The password of the user to login to.
# @constructor
###
class @MagisterBinding
	constructor: (@_homeworkId, @_assignmentId) ->
		@_className = "MagisterBinding"
		@_id = new Meteor.Collection.ObjectID()

		@homeworkId = root.getset "_homeworkId", Match.Optional String
		@assignmentId = root.getset "_assignmentId", Match.Optional String