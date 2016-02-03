###*
# A studyUtil, containing various Files and links teachers can
# put up on their school administration system.
# (Kinda like 'studiewijzers' and 'studiewijzers onderdelen' on Magister in one)
#
# @class StudyUtil
# @consturctor
# @param name {String} The name of the studyUtil.
# @param description {String} A description.
# @param classId {String} The ID of a SchoolClass this studyUtil is for.
# @param ownerId {String} The ID of the owner of this studyUtil.
###
class @StudyUtil
	constructor: (@name, @description, @classId, ownerId) ->
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
		# @type Date|undefined
		# @default undefined
		###
		@visibleTo = undefined

		###*
		# The files in this studyUtil.
		# @proeprty files
		# @type File[]
		# @default []
		###
		@files = []

		###*
		# @property userIds
		# @type String[]
		# @default [ ownerId ]
		###
		@userIds = [ ownerId ]

		###*
		# The name of the externalService that fetched this StudyUtil.
		# @property fetchedBy
		# @type String|undefined
		# @defualt undefined
		###
		@fetchedBy = undefined

		###*
		# @property externalInfo
		# @type Object|undefined
		# @default undefined
		###
		@externalInfo = undefined
