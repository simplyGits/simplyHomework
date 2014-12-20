###*
# Factory for the top level/collection classes, allows for automatic updating if a class is changed.
# The changes of the classes floats up, until they reach the beginning (the factory)
# There it will automatically update the correct Meteor.collection.
#
# Call each method with New.[name of class (without caps)]([params of the constructor of the class])
#
# @variable New
###
@New =
	school: =>
		school = new School arguments...
		@Schools.insert school
		return school

	schedule: =>
		schedule = new Schedule arguments...
		@Schedules.insert schedule
		return schedule

	goaledSchedule: =>
		goaledSchedule = new GoaledSchedule arguments...
		@GoaledSchedules.insert goaledSchedule
		return goaledSchedule

	class: =>
		_class = new SchoolClass arguments...
		@Classes.insert _class
		return _class

	vote: =>
		vote = new Vote arguments...
		@Votes.insert vote
		return vote

	util: =>
		util = new Util arguments...
		@Utils.insert util
		return util

	ticket: =>
		ticket = new Ticket arguments...
		@Tickets.insert ticket
		return ticket

	project: =>
		project = new Project arguments...
		@Projects.insert project
		return project

	calendarItem: =>
		calendarItem = new CalendarItem arguments...
		@CalendarItems.insert calendarItem
		return calendarItem

	schedular: ->
		throw new WrongPlatformException("Schedular is only settable from the client") unless Meteor.isClient

		schedular = new Schedular arguments...
		Meteor.users.update Meteor.userId(), $set: { schedular }
		return schedular

@Get = schedular: (userId) -> _decodeObject (if userId then Meteor.users.findOne(userId) else Meteor.user()).schedular

@_decodeObject = (val) ->
	if _.isObject val
		readyVal = val

		if val._className?
			newInstance = new @[val._className]() 		 # create new instance of same class
			readyVal = uS.defaults val, newInstance		 # copy all the other missing parts
			readyVal.constructor = @[val._className]     # Fix the constructor for nicer debugging <3

		for key in _.keys val
			value = val[key]

			if _.isObject(value) or _.isArray(value) then readyVal[key] = _decodeObject value
		
		return readyVal

	else if _.isArray val then return (_decodeObject item for item in val)
		
	else return val