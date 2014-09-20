root = @

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
	# @param _parent {Object} The creator of this object.
	# @param ownerId {String} The user ID of the owner.
	# @param _homework {Homework}  The homework instance this schedule is made for.
	###
	constructor: (@_parent, @ownerId, @_homework) ->
		@_className = "GoaledSchedule"
		@createTime = Date.now()
		@_scheduledItems = [] # holds scheduleItems, similar to Day.unplannedItems

		@_id = new Meteor.Collection.ObjectID()

		@dependency = new Deps.Dependency

		@items = root.getset "_scheduledItems", [root.ScheduleItem._match], no
		@homework = root.getset "_homework", root.Homework._match

		@addItem = root.add "_scheduledItems", "ScheduleItem"
		@removeItem = root.remove "_scheduledItems", "ScheduleItem"

	classId: -> @homework().classId()
	dueDate: -> @homework().dueDate()
		
	_setDeps: ->
		Deps.autorun (computation) => # Calls the dependency of the sender object, unless it's null
			@dependency.depend()
			@_parent.dependency.changed() if @_parent? and !computation.firstRun

	@_match: (goaledSchedule) ->
		return Match.test schedule, Match.ObjectIncluding
				ownerId: String
				_classId: String
				_dueDate: Date
				_homework: root.Homework._match

	###*
	# Checks if the current Schedule is due for today
	#
	# @method isDue
	# @return {Boolean} If the current Schedule is due for today.
	###
	isDue: -> return EJSON.equals Date.today(), @dueDate()

	###*
	# Returns the tasks that has to be done today.
	#
	# @method tasksForToday
	# @return {Array} Array containing the ScheduleItems that should be done today.
	###
	tasksForToday: -> return @_filterItems (item) => return item.daysAway() is 0
	
	###*
	# Returns the tasks that has to be done on the given Date.
	#
	# @method tasksForDate
	# @param date {Date} The date to get the ScheduleItems for.
	# @return {Array} Array containing the ScheduleItems that should be done on the given Date.
	###
	tasksForDate: (date) -> return @_filterItems (item) => return EJSON.equals item.plannedDate(), date
	
	###*
	# Returns the tasks the user is ahead of.
	#
	# @method tasksAheadOf
	# @return {Array} Array containing the ScheduleItems that the user is ahead of.
	###
	tasksAheadOf: -> return @_filterItems (item) => return item.daysAway() > 0 and item.isDone()
	
	###*
	# Returns the tasks the user is behind of.
	#
	# @method taskBehindOf
	# @return {Array} Array containing the ScheduleItems that the user is behind of.
	###
	taskBehindOf: -> return @_filterItems (item) => return item.daysAway() < 0 and !item.isDone()

	###*
	# Shortcut for _.filter
	#
	# @method _filterItems
	# @param predicate {Function} The predicate to use for _.filter
	# @return {Array} The filtered items.
	###
	_filterItems: (predicate) -> return _.filter @items(), predicate

	class: -> @homework().class()
	classId: -> @homework().classId()