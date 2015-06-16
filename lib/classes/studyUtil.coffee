###*
# A studyUtil, containing various Files and links teachers can
# put up on their school administration system.
# (Kinda like 'studiewijzers' and 'studiewijzers onderdelen' on Magister in one)
#
# @class StudyUtil
# @consturctor
# @param name {String} The name of the studyUtil.
# @param description {String} A description.
# @param classId {ObjectID} The ID of a SchoolClass this studyUtil is for.
# @param ownerId {String} The ID of the owner of this studyUtil.
###
class @StudyUtil
	constructor: (@name, @description, @classId, @ownerId) ->
		@_id = new Meteor.Collection.ObjectID

		###*
		# The date from which this studyUtil is accesible from.
		# @property visibleFrom
		# @type Date
		# @default new Date()
		###
		@visibleFrom = new Date

		###*
		# The date till this studyUtil is accesible.
		# @property visibleTo
		# @type Date|null
		# @default null
		###
		@visibleTo = null

		###*
		# The files in this studyUtil.
		# @proeprty files
		# @type File[]
		# @default []
		###
		@files = []

		###*
		# The name of the externalService that fetched this StudyUtil.
		# @property fetchedBy
		# @type String|null
		# @defualt null
		###
		@fetchedBy = null

		###
		# Info about the external object, ( studyGuide this StudyUtil is from, for exmaple )
		# @property externalInfo
		# @type Object|null
		# @default null
		###
		@externalInfo = null
