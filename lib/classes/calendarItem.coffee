root = @

###
# Note: we don't have a property that
# tracks if the calendarItem is full day,
# to make a calendarItem full day we should
# make the startDate start on 00:00 on day 1
# and end on 00:00 on day 2.
# e.g (begin: 12/02/2015 00:00, 13/02/2015 00:00).
###

###*
# Item in the calendar.
#
# @class CalendarItem
# @param ownerId The ID of the creator of this CalendarItem.
# @param description {String} The description / content of this item.
# @param startDate {Date} The start date of this item.
# @param [endDate] {Date} The end date of this item.
# @param [classId] If this item is linked with a class: the ID of the class; otherwise: null
# @constructor
###
class @CalendarItem
	constructor: (@ownerId, @description, @startDate, @endDate, @classId) ->
		@isDone = no
		@endDate ?= moment(@startDate).add(1, "hour").toDate()

		###*
		# The interval for repeating in seconds.
		# If null, this CalendarItem doesn't repeat.
		# Warning: This method only supports 'dumb' repeats,
		# not something like: "every 20th day of the moth".
		#
		# The start of timing the interval is @startDate.
		# The end is set by @endDate.
		#
		# @property repeatInterval
		# @type Number
		# @default null
		###
		@repeatInterval = null

		###*
		# If this calendarItem is linked to an appointment
		# (eg for giving up homework that isn't filled in
		# into Magister, `appointmentId` will contain the
		# ID of the appointment this calendarItem is linked to.
		#
		# @property appointmentId
		# @type Number
		# @default null
		###
		@appointmentId = null
