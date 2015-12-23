###*
# A project that can be worked on with multiple persons.
# @class Project
# @constructor
# @param name {String} The name of the project. Manually entered or copied from Magister.
# @param [description] {String} The desctiption of the project. Manually entered or copied from Magister.
# @param deadline {Date} The time this project has to be finished.
# @param creatorId {String} The ID of the creator of this project.
# @param [classId] {ObjectID} The ID of the class for this project.
###
class @Project
	constructor: (@name, @description, @deadline, @creatorId, @classId) ->
		@_id = new Meteor.Collection.ObjectID()

		###*
		# The IDs of the participants of this project.
		# @property participants
		# @type String[]
		# @default [ @creatorId ]
		###
		@participants = [ @creatorId ]

		###*
		# The IDs of Google Drive files that are in this project.
		# @property driveFileIds
		# @type String[]
		# @default []
		###
		@driveFileIds = []

		###*
		# The assignment object this Project is coupled with, if any.
		# This should be kept up-to-date with the version provided by the
		# externalService that provided this assignment object.
		#
		# @property assignment
		# @type Assignment
		# @default undefined
		###
		@assignment = undefined
