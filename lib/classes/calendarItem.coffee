root = @

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
		@_id = new Meteor.Collection.ObjectID()
		@isDone = no
		@endDate ?= moment(@_startDate).add(1, "hour").toDate()