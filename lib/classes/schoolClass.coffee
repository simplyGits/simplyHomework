root = @
class @SchoolClass
	constructor: (name, course, @year, schoolVariant) ->
		@_id = new Meteor.Collection.ObjectID()
		
		@course = course?.toLowerCase()
		@schoolVariant = schoolVariant?.toLowerCase()
		@name = Helpers.cap name if name?
		
		@schedules = [] # Contains schedule ID's.
		@books = []

	###*
	# Returns a cursor pointing to the schedules with this class' ID
	#
	# @method schedules
	# @return {Cursor} A cursor pointing to the schedules with this class' ID
	###
	getSchedules: -> return Schedules.find { _class: { _id: @_id }, isPublic: yes }

	addSchedule: (schedule) ->
		if (schedule = Schedules.findOne(schedule._id))?
			schedule.classId @_id
		else
			throw new NotFoundException "Couldn't find the given schedule in the Schedules collection."

	removeSchedule: (schedule) ->
		if (schedule = Schedules.findOne(schedule._id))?
			schedule.classId null
		else
			throw new NotFoundException "Couldn't find the given schedule in the Schedules collection."

	getGrades: (iMagisterRetreiver, userId, callback) ->
		#iMagisterRetreiver.on "grades", (e, r) ->

	getGradeWeigthSum: (iMagisterRetreiver, userId) ->
		sum = 0
		sum += g.weigth() for g in @getGrades iMagisterRetreiver, userId
		return sum

	getGradeAverage: (iMagisterRetreiver, userId, defaultGrade = 5.5) ->
		if (grades = @getGrades iMagisterRetreiver, userId).length isnt 0
			return Helpers.getAverage grades, (g) -> g.grade() * g.weigth()
		else if _.isNumber defaultGrade
			return defaultGrade
		else
			throw new ArgumentException "defaultGrade", "No grades found and expected number, got #{typeof defaultGrade}"