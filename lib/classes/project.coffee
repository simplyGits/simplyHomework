root = @

class @Project
	###*
	# Constructor of the Project class.
	#
	# @method constructor
	# @param _parent {Object} The parent of the object
	# @param _magisterBinding {MagisterBinding} The binding between the homework / assignment object.
	#
	###
	constructor: (@_parent, @_name, @_description, @_deadline, @_magisterBinding, @_classId, @_creatorId) ->
		@_className = "Project"
		@_id = new Meteor.Collection.ObjectID()

		@_participants = [ @_creatorId ]

		@name = root.getset "_name", String
		@description = root.getset "_description", String
		@deadline = root.getset "_deadline", Date
		@magisterBinding = root.getset "_magisterBinding", root.MagisterBinding._match
		@classId = root.getset "_classId", String, yes, null, (id) -> new Meteor.Collection.ObjectID id._str
		@creatorId = root.getset "_creatorId", String
		@participants = root.getset "_participants", [String], no

	addParticipant: (userId) ->
		throw new NotFoundException "No user with this ID found!" if Meteor.users.find(userId).count() is 0
		@_participants.push userId
		Projects.update @_id, $push: "_participants": userId

	removeParticipant: (userId) ->
		throw new NotFoundException "No user with this ID found!" if !_.contains(@participants(), userId)
		@_participants.remove userId
		Projects.update @_id, $pull: "_participants": userId

	bindedWithMagister: -> return @magisterBinding()?