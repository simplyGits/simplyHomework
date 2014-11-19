root = @

###*
# Task in a goaledSchedule.
#
# @class Task
###
class @Task
	###*
	# Constructor for the Task class.
	#
	# @method constructor
	# @param content \\!!TODO!!//
	# @param _paragraphId {String} The ID of the paragraph this Task is for.
	# @param plannedDate {Date} Date object for the date this Task is planned for. Can also be a bool false flag.
	###
	constructor: (@_content, @_paragraphId, @_plannedDate, @_priority, @_repeat = no, @_generator) ->
		@creationDate = new Date
		@_isDone = false

		@_className = "Task"

		@content = root.getset "_content"
		@paragraphId = root.getset "_paragraphId", String
		@plannedDate = root.getset "_plannedDate", Date
		@isDone = root.getset "_isDone", Boolean
		@priority = root.getset "_priority", Number
		@repeat = root.getset "_repeat", Boolean
		@generator = root.getset "_generator", String

	###*
	# Returns if the current Task is planned for a date.
	#
	# @method isPlanned
	# @return {Boolean} True if the current Task is planned, otherwise: false.
	###
	isPlanned: -> return Match.test @plannedDate(), Date

	isForDate: (date) ->
		if @isPlanned()
			return EJSON.equals date, @plannedDate()
		else
			throw new NotSupportedException "This Task isn't planned" 


	isForToday: -> @isForDate Date.today() 

	###*
	# Return the days away of the planned date for this Task.
	# Throws a NotSupportedException if the current Task isn't scheduled.
	#
	# @method daysAway
	# @return {Number} Number of days between the planned date and today
	###
	daysAway: ->
		if @isPlanned()
			return Helpers.daysRange(Date.today(), @plannedDate())
		else
			throw new NotSupportedException "This Task isn't planned"