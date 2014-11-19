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
	school: (params...) =>
		school = new School params...
		@Schools.insert school
		return school

	schedule: (params...) =>
		schedule = new Schedule params...
		@Schedules.insert schedule
		return schedule

	goaledSchedule: (params...) =>
		goaledSchedule = new GoaledSchedule params...
		@GoaledSchedules.insert goaledSchedule
		return goaledSchedule

	class: (params...) =>
		_class = new Class params...
		@Classes.insert _class
		return _class

	vote: (params...) =>
		vote = new Vote params...
		@Votes.insert vote
		return vote

	util: (params...) =>
		util = new Util params...
		@Utils.insert util
		return util

	ticket: (params...) =>
		ticket = new Ticket params...
		@Tickets.insert ticket
		return ticket

	project: (params...) =>
		project = new Project params...
		@Projects.insert project
		return project

	schedular: (params...) ->
		throw new WrongPlatformException("Schedular is only settable from the client") unless Meteor.isClient

		schedular = new Schedular params...
		Meteor.users.update Meteor.userId(), $set: { schedular }
		return schedular

@Get = #needed for serverside, also has additions for some client side shit.
	schedular: -> if !Meteor.user().schedular? then null else _decodeObject Meteor.user().schedular
	
	classes: (query = {}, options = {}) =>
		if Meteor.isServer
			Classes.find query, _.extend options, transform: (c) => @_decodeObject c
		else
			Classes.find query, options
	goaledSchedules: (query = {}, options = {}) =>
		if Meteor.isServer
			GoaledSchedules.find query, _.extend options, transform: (gs) => @_decodeObject gs
		else
			GoaledSchedules.find query, options
	schools: (query = {}, options = {}) =>
		if Meteor.isServer
			Schools.find query, _.extend options, transform: (s) => @_decodeObject s
		else
			Schools.find query, options
	projects: (query = {}, options = {}) =>
		if Meteor.isServer
			Projects.find query, _.extend options, transform: (p) => @_decodeObject p
		else
			Projects.find query, options

@_decodeObject = (val, sender) ->
	if _.isObject val
		readyVal = val

		if val._className?
			newInstance = new @[val._className]() 		 # create new instance of same class
			readyVal = uS.defaults val, newInstance		 # copy all the other missing parts
			readyVal.constructor = @[val._className]     # Fix the constructor for nicer debugging <3

		for key in _.keys val
			value = val[key]

			if _.isArray(value)
				readyVal[key] = (_decodeObject(item, readyVal) for item in value)
			else
				readyVal[key] = _decodeObject(value, readyVal)
		
		return readyVal

	else if _.isArray val then return (_decodeObject(item, sender) for item in val)
		
	else return val