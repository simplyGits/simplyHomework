results = {}
callbacks = {}
dependencies = {}
@magister = null

@pushMagisterResult = (name, result) ->
	check name, String

	results[name] = result
	for { callback, dependency } in callbacks[name] ? []
		callback(result.error, result.result)
		dependency.changed()

@onMagisterInfoResult = (name, callback) ->
	# If callback is null, it will use a tracker to rerun computations, otherwise it will just recall the given callback.
	check name, String
	check callback, Match.Optional Function

	callbacks[name] ?= []
	callbacks[name].push { callback, dependency: new Tracker.Dependency }
	callbacks[name].dependency.depend() unless callback?

	if (result = results[name])?
		callback result.error, result.result
		return result

@resetMagisterLoader = ->
	results = {}
	callbacks = {}
	@magister = null

@loadMagisterInfo = (force = no) ->
	pushResult = @pushMagisterResult
	check force, Boolean
	if not force and @magister? then throw new Error "loadMagisterInfo already called. To force reloading all info use loadMagisterInfo(true)."

	try
		url = "https://#{Schools.findOne(Meteor.user().profile.schoolId).url}"
	catch
		console.warn "Couldn't retreive school info!"
		return
	{ username, password } = Meteor.user().magisterCredentials

	(@magister = new Magister({ url }, username, password, no)).ready (m) ->
		m.appointments new Date(), new Date().addDays(7), no, (error, result) -> # Currently we AREN'T downloading the persons.
			pushResult "appointments this week", { error, result }
			unless error?
				pushResult "appointments tomorrow", error: null, result: _.filter result, (a) -> a.begin() > Date.today().addDays(1) and a.begin() < Date.today().addDays(1)
			else
				pushResult "appointments tomorrow", { error, result: null }

		m.courses (e, r) ->
			if e?
				pushResult "classes", { error: e, result: null }
				pushResult "course", { error: e, result: null }
			else
				r[0].classes (error, result) -> pushResult "classes", { error, result }
				pushResult "course", { error: null, result: r[0] }

		m.assignments no, (error, result) ->
			pushResult "assignments", { error, result }
			if error? then pushResult "assignments soon", { error, result: null }
			else pushResult "assignments soon", error: null, result: _.filter(result, (a) -> a.deadline().date() < Date.today().addDays(7) and not a.finished() and new Date() < a.deadline())

	return "dit geeft echt niets nuttig terug ofzo, als je dat denkt."