###*
# Converts a grade to a number, can be Dutch grade style or English. More can be added.
# If the `grade` can't be converted it will return NaN.
#
# @method gradeConverter
# @param grade {String|Number} The grade to convert.
# @return {Number} `grade` converted to a number. Defaults to NaN.
###
@gradeConverter = (grade) ->
	return undefined unless grade?
	return grade if _.isNumber grade

	# Normal Dutch grades
	val = grade.replace(",", ".").replace(/[^\d\.]/g, "")
	unless val.length is 0 or _.isNaN(+val)
		return +val

	# English grades
	englishGradeMap =
		"F": 1.7
		"E": 3.3
		"D": 5.0
		"C": 6.7
		"B": 8.3
		"A": 10.0

	if _(englishGradeMap).keys().contains(grade.toUpperCase())
		return englishGradeMap[grade.toUpperCase()]

	return NaN

###*
# A serverside database stored grade.
#
# @class StoredGrade
# @constructor
# @param grade {Number} The grade as a Number, the grade should be converted by a converter first if it wasn't a number at first.
# @param weight {Number} The weight of the grade.
# @param dateFilledIn {Date} The date on which the grade was entered by the teacher or, if unknown, by the student.
# @param classId {ObjectID} The ID of the Class which this grade is for.
# @param ownerId {String} The ID of the owner of this grade.
###
class @StoredGrade
	constructor: (@grade, @weight, @dateFilledIn, @classId, @ownerId) ->
		@_id = new Meteor.Collection.ObjectID()

		###*
		# The ID of the Grade on the external service (eg Magister)
		# if it comes from one.
		# @property externalId
		# @type mixed
		# @default null
		###
		@externalId = null

		###*
		# A description describing what this grade is for.
		# @property description
		# @type String
		# @default null
		###
		@description = null

		###*
		# Whether or not @grade was sufficient to pass.
		# @property passed
		# @type Boolean
		# @default @grade >= 5.5
		###
		@passed = @grade >= 5.5

		###*
		# Whether or not this grade is an 'end' grade (average class grade)
		# @property isEnd
		# @type Boolean
		# @default null
		###
		@isEnd = null

		###*
		# The dbName of the externalService that fetched this Grade.
		# @property fetchedBy
		# @type String
		# @default null
		###
		@fetchedBy = null

	toString: (precision = 2) -> @grade.toPrecision precision
	valueOf: -> @grade

	###*
	# Converts the given _filled_ Magister Grade to a ExternalGrade
	#
	# @method fromMagisterGrade
	# @static
	# @param grade {Grade} The grade to convert.
	# @param userId {String} The ID of the User object that owns `grade`.
	# @return {StoredGrade} `grade` converted to a StoredGrade.
	###
	@fromMagisterGrade: (grade, userId) ->
		user = Meteor.users.findOne userId

		weight = if grade.counts() ? yes then grade.weight() else 0
		classId = _.filter(user.classInfos, (i) -> i.magisterId is grade.class().id()).id

		storedGrade = new StoredGrade(
			gradeConverter(grade.grade()),
			weight,
			grade.dateFilledIn(),
			classID,
			userId
		)

		storedGrade.externalId = grade.id()
		storedGrade.description = grade.description().trim()
		storedGrade.passed = grade.passed() ? storedGrade.passed
		storedGrade.fetchedBy = "magister"

		return storedGrade
