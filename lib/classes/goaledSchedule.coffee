###
# A GoaledSchedule has a goal. e.g. Learning chapter 4 for German for a coming test.
# A GoaledSchedule leads the user to the goal and makes creates a ScheduleItem for every day.
# It should be fully automatic, if an user finishes a scheduleItem before the planned date the schedule should automatically update
#
# @class GoaledSchedule
###
class @GoaledSchedule
	###*
	# Constructor of the GoaledSchedule class.
	#
	# @method constructor
	# @param ownerId {String} The user ID of the owner.
	# @param parsedData {ParsedData} The parsed homework data.
	# @param dueDate {Date} The date of the end of this goaledSchedule.
	# @param classId {ObjectID} The ID of the class this goaledSchedule is for.
	###
	constructor: (@ownerId, @parsedData, @dueDate, @classId) ->
		@_id = new Meteor.Collection.ObjectID()

		@createTime = Date.now()
		@tasks = []

		###*
		# The ID of the CalendarItem this GoaledSchedule is for.
		#
		# @property calendarItemId
		# @type String|null
		# @default null
		###
		@calendarItemId = null

		###*
		# The weight of the coming test / quiz.
		# If there's no weight available the value should be null.
		# Used by schedular to caculate the priority.
		#
		# @property weight
		# @type Number
		# @default null
		###
		@weight = null
