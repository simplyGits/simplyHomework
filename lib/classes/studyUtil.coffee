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
###
class @StudyUtil
	constructor: (@name, @description, @classId) ->
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
		# @type Date
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
	# Converts the given StudyGuidePart to a StudyUtil.
	# @method fromMagister
	# @static
	# @param part {StudyGuidePart} The StudyGuidePart to convert.
	# @param studyGuide {StudyGuide} The parent StudyGuide of `part` to use for converting the `part`.
	# @param files {File[]} The files of the given `part`.
	# @param [classId] {ObjectID} An ID used to overwrite the ID found in the studyGuide.
	# @return {StudyUtil} The converted StudyGuide as a StudyUtil
	###
	@fromMagister: (part, studyGuide, files, classId) ->
		unless classId?
			classInfo = _.find Meteor.user().classInfos, (i) -> i.magisterAbbreviation is studyGuide._class
			classId = classInfo.id

		studyUtil = new StudyUtil part.name(), part.description(), classId

		studyUtil.visibleFrom = part.from()
		studyUtil.visibleTo = part.to()
		# TODO == Find a good universal file class profile and make a magister
		# file converter for it.
		#studyUtil.files = xxx.fromMagister files

		return studyUtil
