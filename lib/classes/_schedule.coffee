root = @

###*
# Contains the lessons per class. Mostly used if somebody filled in a schedule that is relevant for a whole class.
# Schedules don't have a goal.
#
# @class Schedule
###
class @Schedule
	###
	# Constructor for the Schedule class.
	#
	# @method constructor
	# @param _parent {Object} The creator of this object.
	# @param _classId {String} The ID of the class this schedule is for.
	# @param ownerId {String} The user's ID of the owner of this schedule
	# @param isPublic {Boolean} Whether the schedule is public and should be shared with everybody on the same class.
	###
	constructor: (@_parent, @_classId, @ownerId, @_isPublic) ->
		@_className = "Schedule"
		@_id = new Meteor.Collection.ObjectID()
		@_scheduleItems = [] # containing ScheduleItem instances.
		
		@dependency = new Deps.Dependency

		@classId = root.getset "_classId", String
		@isPublic = root.getset "_isPublic", Boolean
		@items = root.getset "_scheduleItems", [root.ScheduleItem._match], no

		@addItem = root.add "_scheduleItems", "ScheduleItem"
		@removeItem = root.remove "_scheduleItems", "ScheduleItem"

	_setDeps: ->
		Deps.autorun (computation) => # Calls the dependency of the sender object, unless it's null
			@dependency.depend()
			@_parent.dependency.changed() if @_parent? and !computation.firstRun

	@_match: (schedule) ->
		return Match.test schedule, Match.ObjectIncluding
				_class: String
				_isPublic: Boolean
				_scheduleItems: [root.ScheduleItem._match]

	class: -> return root.Classes.findOne @classId()

	hasItemForToday: -> return _.some @_scheduleItems, (sI) -> return sI.daysAway() is 0

	###*
	# Shortcut for `this.isPublic(true)`.
	#
	# @method shareWithClass
	###
	shareWithClass: -> @isPublic(yes)