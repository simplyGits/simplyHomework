root = @

###*
# Class to repesent a book / 'methode'
#
# @class CalendarItem
###
class @CalendarItem
	###*
	# Constructor of the CalendarItem class.
	#
	# @method constructor
	# @param _ownerId The ID of the creator of this CalendarItem.
	# @param _description {String} The description / content of this item.
	# @param _startDate {Date} The start date of this item.
	# @param [_endDate] {Date} The end date of this item.
	# @param [_classId] If this item is linked with a class: the ID of the class; otherwise: null
	###
	constructor: (@_ownerId, @_description, @_startDate, @_endDate, @_classId) ->
		@_className = "CalendarItem"
		@_id = new Meteor.Collection.ObjectID()

		@ownerId = root.getset "_ownerId"
		@description = root.getset "_description", String
		@startDate = root.getset "_startDate", Date
		@endDate = root.getset "_endDate", Date
		@classId = root.getset "_classId"