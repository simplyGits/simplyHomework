englishGradeMap =
	'F': 1.7
	'E': 3.3
	'D': 5.0
	'C': 6.7
	'B': 8.3
	'A': 10.0

###*
# Converts a grade to a number, can be Dutch grade style or English. More can be added.
# If the `grade` can't be converted it will return NaN.
#
# @method gradeConverter
# @param grade {String|Number} The grade to convert.
# @return {Number} `grade` converted to a number. Defaults to NaN.
###
gradeConverter = (grade) ->
	return grade if _.isFinite grade
	check grade, String
	number = parseFloat grade.replace(',', '.').replace(/[^\d\.]/g, '')

	# Normal Dutch grades
	return number unless _.isNaN number

	# English grades
	number = englishGradeMap[grade.toUpperCase()]
	return number if number?

	# TODO: This seems like it's never called.
	# Percentages
	if _.isString(grade) and grade[-1..] is '%' and not _.isNaN number
		return number

	NaN

###*
# A serverside database stored grade.
#
# @class Grade
# @constructor
# @param grade {String|Number}
# @param weight {Number} The weight of the grade.
# @param classId {ObjectID} The ID of the Class which this grade is for.
# @param ownerId {String} The ID of the owner of this grade.
###
class @Grade
	@gradeConverter: gradeConverter

	constructor: (grade, @weight, @classId, @ownerId) ->
		@_id = new Meteor.Collection.ObjectID()

		###*
		# The grade guaranteed to be a number.
		# Will be NaN if the grade failed to convert to a number.
		#
		# @property grade
		# @type Number
		###
		@grade = gradeConverter grade

		###*
		# The grade guaranteed to be a string.
		#
		# @property gradeStr
		# @type String
		###
		@gradeStr = switch typeof grade
			when 'string' then grade
			when 'number' then grade.toPrecision 2

		###*
		# Can be one of: [ 'number', 'percentage' ]
		# @property gradeType
		# @type String
		# @default 'number'
		###
		@gradeType = 'number'

		###*
		# A description describing what this grade is for.
		# @property description
		# @type String
		# @default ""
		###
		@description = ''

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
		# @type Boolean|null
		# @default null
		###
		@isEnd = null

		###*
		# The date on which the grade was entered by the teacher or, if unknown,
		# by the student.
		#
		# @property dateFilledIn
		# @type Date
		# @default null
		###
		@dateFilledIn = null

		###*
		# The date on which the test or assignment was made for this grade.
		# This can be filled in incorrectly by the teacher.
		#
		# @property dateTestMade
		# @type Date
		# @default null
		###
		@dateTestMade = null

		###*
		# The ID of the Grade on the external service (eg Magister)
		# if it comes from one.
		#
		# @property externalId
		# @type mixed
		# @default null
		###
		@externalId = null

		###*
		# The name of the externalService that fetched this Grade.
		# @property fetchedBy
		# @type String|null
		# @default null
		###
		@fetchedBy = null

		###*
		# @property period
		# @type GradePeriod
		###
		@period = null

	class: -> Classes.findOne @classId
	toString: (precision = 2) -> @gradeStr ? @grade.toPrecision precision
	valueOf: -> @grade

###*
# @class GradePeriod
# @constructor
# @param id {any} The ID of the gradePeriod.
# @param [name] {String} The name of this period.
###
class @GradePeriod
	constructor: (id, name) ->
		###*
		# @property id
		# @type any
		###
		@id = id

		###*
		# @property name
		# @type String|null
		###
		@name = name

		###*
		# @property from
		# @type Date|null
		###
		@from = null

		###*
		# @property to
		# @type Date|null
		###
		@to = null

	toString: -> @name
