root = @

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
	school: (params...) ->
		school = new School null, params...
		root.Schools.insert _makeValueStorable school, no
		return _setDeps.school _decodeObject school

	schedule: (params...) ->
		schedule = new Schedule null, params...
		root.Schedules.insert _makeValueStorable schedule, no
		return _setDeps.schedule _decodeObject schedule

	goaledSchedule: (params...) ->
		goaledSchedule = new GoaledSchedule null, params...
		root.GoaledSchedules.insert _makeValueStorable goaledSchedule, no
		return _setDeps.goaledSchedule _decodeObject goaledSchedule

	class: (params...) ->
		_class = new Class null, params...
		root.Classes.insert _makeValueStorable _class, no
		return _setDeps.class _decodeObject _class

	vote: (params...) ->
		vote = new Vote null, params...
		root.Votes.insert _makeValueStorable vote, no
		return _setDeps.vote _decodeObject vote

	util: (params...) ->
		util = new Util null, params...
		root.Utils.insert _makeValueStorable util, no
		return _setDeps.util _decodeObject util

	ticket: (params...) ->
		ticket = new Ticket null, params...
		root.Tickets.insert _makeValueStorable ticket, no
		return _setDeps.ticket _decodeObject ticket

	project: (params...) ->
		project = new Project null, params...
		root.Projects.insert _makeValueStorable project, no
		return _setDeps.project _decodeObject project

	schedular: (params...) ->
		throw new WrongPlatformException("Schedular is only settable from the client") if !Meteor.isClient

		schedular = new Schedular null, params...
		Meteor.users.update Meteor.userId(), $set: { schedular }
		return _setDeps.schedular _decodeObject schedular

@Get = # required for serverside, also has additions for some client side shit.
	schedular: -> if !Meteor.user().schedular? then null else _setDeps.schedular _decodeObject Meteor.user().schedular
	
	classes: (query = {}, options = {}) ->
		if Meteor.isServer
			Classes.find query, _.extend options, transform: (c) -> root._decodeObject c
		else
			Classes.find query, options
	goaledSchedules: (query = {}, options = {}) ->
		if Meteor.isServer
			GoaledSchedules.find query, _.extend options, transform: (gs) -> return root._decodeObject gs
		else
			GoaledSchedules.find query, options
	schools: (query = {}, options = {}) ->
		if Meteor.isServer
			Schools.find query, _.extend options, transform: (s) -> return root._decodeObject s
		else
			Schools.find query, options
	projects: (query = {}, options = {}) ->
		if Meteor.isServer
			Projects.find query, _.extend options, transform: (p) -> return root._decodeObject p
		else
			Projects.find query, options

@_setDeps =
	# Array's filled with IDs to prevent making multiple DEP Computations for one instance.
	schools:   []
	schedules: []
	goaledSchedules: []
	classes:   []
	votes:     []
	utils:     []
	tickets:   []
	projects:  []
	schedulars:[]

	school: (school) ->
		return school if _.contains @schools, school._id
		@schools.push school._id

		Deps.autorun (computation) ->
			school.dependency.depend()
			root.Schools.update(school._id, $set: _makeValueStorable school) unless computation.firstRun

		return school

	schedule: (schedule) ->
		return schedule if _.contains @schedules, schedule._id
		@schedules.push schedule.id

		Deps.autorun (computation) ->
			schedule.dependency.depend()
			root.Schedules.update(schedule._id, $set: _makeValueStorable schedule) unless computation.firstRun

		return schedule

	goaledSchedule: (goaledSchedule) ->
		return goaledSchedule if _.contains @goaledSchedules, goaledSchedule._id
		@goaledSchedules.push goaledSchedule._id

		Deps.autorun (computation) ->
			goaledSchedule.dependency.depend()
			root.GoaledSchedules.update(goaledSchedule._id, $set: _makeValueStorable goaledSchedule) unless computation.firstRun

		return goaledSchedule

	class: (_class) ->
		return _class if _.contains @classes, _class._id
		@classes.push _class._id

		Deps.autorun (computation) ->
			_class.dependency.depend()
			root.Classes.update(_class._id, $set: _makeValueStorable _class) unless computation.firstRun

		return _class

	vote: (vote) ->
		return vote if _.contains @votes, vote._id
		@votes.push vote._id

		Deps.autorun (computation) ->
			vote.dependency.depend()
			root.Votes.update(vote._id, $set: _makeValueStorable vote) unless computation.firstRun

		return vote

	util: (util) ->
		return util if _.contains @utils, util._id
		@utils.push util._id

		Deps.autorun (computation) ->
			util.dependency.depend()
			root.Utils.update(util._id, $set: _makeValueStorable util) unless computation.firstRun

		return util

	ticket: (ticket) ->
		return ticket if _.contains @tickets, ticket._id
		@tickets.push ticket._id

		Deps.autorun (computation) ->
			ticket.dependency.depend()
			root.Tickets.update(ticket._id, $set: _makeValueStorable ticket) unless computation.firstRun

		return ticket

	project: (project) ->
		return project if _.contains @projects, project._id
		@projects.push project._id

		Deps.autorun (computation) ->
			project.dependency.depend()
			root.Projects.update(project._id, $set: _makeValueStorable project) unless computation.firstRun

		return project

	schedular: (schedular) ->
		return schedular if _.contains @schedulars, schedular._id
		@schedulars.push schedular._id

		Deps.autorun (computation) ->
			schedular.dependency.depend()
			Meteor.users.update(schedular.userId, $set: { schedular: _makeValueStorable schedular }) unless computation.firstRun

		return schedular

_makeValueStorable = (val, update = yes) ->
	if _.isObject val
		readyVal = val

		readyVal._parent = null if val._parent?
		readyVal.dependency = null if val.dependency?
		delete readyVal["_id"] if update

		for key in _.keys val
			value = val[key]

			if _.isArray(value) or _.isObject(value)
				readyVal[key] = _makeValueStorable value

		return readyVal

	else if _.isArray val then return (_makeValueStorable item for item in val)

@_decodeObject = (val, sender) ->
	if _.isObject val
		readyVal = val

		if val._className? and !val._parent?
			readyVal._parent = sender           		 # fix sender
			newInstance = new @[val._className]() 		 # create new instance of same class
			readyVal = uS.defaults val, newInstance		 # copy all the other missing parts
			readyVal.constructor = @[val._className]     # Fix the constructor for nicer debugging <3

		for key in _.keys val
			value = val[key]

			readyVal[key] = (_decodeObject(item, readyVal) for item in value) if _.isArray(value)
			readyVal[key] = _decodeObject(value, readyVal) if key isnt "_parent" and key isnt "dependency"
		
		return readyVal

	else if _.isArray val then return (_decodeObject(item, sender) for item in val)
		
	else return val

@store = _makeValueStorable