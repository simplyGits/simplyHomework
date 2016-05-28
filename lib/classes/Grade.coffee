englishGradeMap =
	'F': 1.7
	'E': 3.3
	'D': 5.0
	'C': 6.7
	'B': 8.3
	'A': 10.0

dutchGradeMap =
	'ZS': 1
	'S': 2
	'ROV': 3
	'OV': 4
	'V': 6
	'RV': 7
	'G': 8
	'ZG': 9
	'U': 10

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

	# Normal Dutch grades and percentages
	return number unless _.isNaN number

	# English grades
	number = englishGradeMap[grade.toUpperCase()]
	return number if number?

	# Dutch grades like 'V' and 'OV'
	number = dutchGradeMap[grade.toUpperCase().replace /(\+|-)$/, '']
	if number?
		return (
			last = grade[-1..]
			if last is '-' then number - .25
			else if last is '+' then number + .25
			else number
		)

	NaN

###*
# A server side database stored grade.
#
# @class Grade
# @constructor
# @param grade {String|Number}
# @param weight {Number} The weight of the grade.
# @param classId {String} The ID of the Class which this grade is for.
# @param ownerId {String} The ID of the owner of this grade.
###
class @Grade
	@gradeConverter: gradeConverter

	constructor: (grade, @weight, @classId, @ownerId) ->
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
			when 'number' then grade.toPrecision(2).replace '.', ','

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
		# @default undefined
		###
		@dateFilledIn = undefined

		###*
		# The date on which the test or assignment was made for this grade.
		# This can be filled in incorrectly by the teacher.
		#
		# @property dateTestMade
		# @type Date|undefined
		# @default undefined
		###
		@dateTestMade = undefined

		###*
		# The ID of the Grade on the external service (eg Magister)
		# if it comes from one.
		#
		# @property externalId
		# @type mixed
		# @default undefined
		###
		@externalId = undefined

		###*
		# The name of the externalService that fetched this Grade.
		# @property fetchedBy
		# @type String|undefined
		# @default undefined
		###
		@fetchedBy = undefined

		###*
		# @property period
		# @type GradePeriod
		###
		@period = null

	###*
	# Returns whether or not the current grade is the highest possible on the
	# grade scale it uses.
	#
	# @method isPerfect
	# @return {Boolean}
	###
	isPerfect: ->
		@passed and @grade is (
			switch @gradeType
				when 'number' then 10
				when 'percentage' then 100
		)

	class: -> Classes.findOne @classId
	toString: (precision = 2) -> @gradeStr ? @grade.toPrecision precision
	valueOf: -> @grade

	@schema: new SimpleSchema
		grade:
			type: null
			custom: -> _.isNumber @value
		gradeStr:
			type: String
		gradeType:
			type: String
			allowedValues: [ 'number', 'percentage' ]
		weight:
			type: Number
			decimal: yes
			min: 0
		classId:
			type: String
			optional: yes # REVIEW
		ownerId:
			type: String
		description:
			type: String
			trim: yes
			optional: yes
		passed:
			type: Boolean
		isEnd:
			type: Boolean
		dateFilledIn:
			type: Date
		dateTestMade:
			type: Date
			optional: yes
		externalId:
			type: null
			optional: yes
		fetchedBy:
			type: String
			optional: yes
		period:
			type: null
			blackbox: yes
		###
		# TODO: This had problems because in magister-binding we're returning a stored
		# grade when it hasn't changed, this grade from the database doesn't have a
		# GradePeriod type but an object type thanks to how EJSON stringification.
		period:
			type: GradePeriod
		###

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

@Grades = new Mongo.Collection 'grades', transform: (g) ->
	g = _.extend new Grade(g.gradeStr), g
	if Meteor.isServer
		g
	else
		_.extend g,
			__insufficient: if g.passed then '' else 'insufficient'

			# TODO: do this on a i18n friendly way.
			__grade: g.toString().replace '.', ','
			__weight: (
				if Math.floor(g.weight) is g.weight
					g.weight
				else
					g.weight.toFixed(1).replace '.', ','
			)
@Grades.attachSchema Grade.schema
