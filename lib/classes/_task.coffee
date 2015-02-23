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
	constructor: (@content, @bookId, @chapter, @paragraph, @plannedDate, @priority, @repeat = no, @generator) ->
		@_id = new Meteor.Collection.ObjectID

		@creationDate = new Date
		@isDone = false
