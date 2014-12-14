root = @

class @Project
	###*
	# Constructor of the Project class.
	#
	# @method constructor
	# @param _magisterBinding {MagisterBinding} The binding between the homework / assignment object.
	#
	###
	constructor: (@name, @description, @deadline, @magisterBinding, @classId, @creatorId) ->
		@_className = "Project"
		@_id = new Meteor.Collection.ObjectID()

		@participants = [ @creatorId ]

	bindedWithMagister: -> return @magisterBinding()?