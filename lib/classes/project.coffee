###*
# A project that can be worked on with multiple persons.
# @class Project
# @constructor
# @param name {String} The name of the project. Manually entered or copied from Magister.
# @param [description] {String} The desctiption of the project. Manually entered or copied from Magister.
# @param deadline {Date} The time this project has to be finished.
# @param ownerId {String} The ID of the owner / admin of this project.
# @param [classId] {ObjectID} The ID of the class for this project.
# @param [magisterId] {Number} The ID of the magister assignment, if any.
###
class @Project
	constructor: (@name, @description, @deadline, @ownerId, @classId, @magisterId) ->
		@_id = new Meteor.Collection.ObjectID()

		###*
		# The IDs of the participants of this project.
		# @property participants
		# @type String[]
		# @default [ @ownerId ]
		###
		@participants = [ @ownerId ]

		###*
		# The IDs of Google Drive files that are in this project.
		# @property driveFileIds
		# @type String[]
		# @default []
		###
		@driveFileIds = []
