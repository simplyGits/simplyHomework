root = @

class @Project
	###*
	# Constructor of the Project class.
	#
	# @method constructor
	# @param _magisterBinding {MagisterBinding} The binding between the homework / assignment object.
	#
	###
	constructor: (@name, @description, @deadline, @magisterId, @classId, @ownerId) ->
		@_className = "Project"
		@_id = new Meteor.Collection.ObjectID()

		@participants = [ @ownerId ]

	bindedWithMagister: -> return @magisterId()?