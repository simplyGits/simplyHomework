@HomeworkType =
	"Unknown"     : 0
	"Normal"      : 1
	"Test"        : 2
	"Exam"        : 3
	"Quiz"        : 4
	"OralTest"    : 5
	"Information" : 6

###*
# Class for a homework item.
#
# @class Homework
###
class @Homework
	constructor: (@description, @dueDate, @classId, @homeworkType, @isPublic) ->
		@_id = new Meteor.Collection.ObjectID

		###
		# If this homework instance wasn't added manually, the ID of the Magister appointment.
		#
		# @property appointmentId
		# @default null
		###
		@appointmentId = null

		###
		# If this homework instance was added manually, the ID of the CalendarItem.
		#
		# @property calendarItemId
		# @default null
		###
		@calendarItemId = null
