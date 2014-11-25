results = {}
callbacks = {}
dependencies = {}
@magister = null

validSensitivities = ["default", "info update", "rerun"]

@pushMagisterResult = (name, sensitivity, result) ->
	check name, String

	results[name] = result
	for callback in callbacks[name]?.callbacks ? []
		callback(result.error, result.result)
		_.remove callbacks[name].callbacks, callback if callbacks[name].once
		callbacks[name].dependency.changed()

@onMagisterInfoResult = ->
	# If callback is null, it will use a tracker to rerun computations, otherwise it will just recall the given callback.
	name = _.find arguments, (a) -> _.isString a
	once = _.find(arguments, (a) -> _.isBoolean a) ? no
	callback = _.find arguments, (a) -> _.isFunction a
	throw new ArgumentException "name", "Can't be null" unless name?

	callbacks[name] ?= { callbacks: [], dependency: new Tracker.Dependency, once }
	callbacks[name].callbacks.push callback
	callbacks[name].dependency.depend() unless callback?

	if (result = results[name])?
		callback? result.error, result.result
		_.remove callbacks[name].callbacks, callback if once
		return result

@resetMagisterLoader = ->
	results = {}
	callbacks = {}
	@magister = null

@loadMagisterInfo = (sensitivity = "default") ->
	pushResult = @pushMagisterResult
	time = Session.get("loadMagsterInfoTimesCalled") ? 0

	unless _.contains validSensitivities, sensitivity
		throw new ArgumentException "sensitivity", "Option #{sensitivity} isn't valid: Valid chooses are: [#{validSensitivities.join ", "}]"

	if sensitivity is "default" and @magister? then throw new Error "loadMagisterInfo already called. To force reloading all info use loadMagisterInfo(true)."

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

		if time % 6 is 0 or sensitivity is "info update"
			m.courses (e, r) ->
				if e?
					pushResult "classes", { error: e, result: null }
					pushResult "course", { error: e, result: null }
					pushResult "grades", { error: e, result: null }
				else
					r[0].classes (error, result) -> pushResult "classes", { error, result }
					r[0].grades no, (error, result) -> pushResult "grades", { error, result }
					pushResult "course", { error: null, result: r[0] }

		if time % 3 is 0 or sensitivity is "info update"
			m.assignments no, (error, result) ->
				pushResult "assignments", { error, result }
				if error? then pushResult "assignments soon", { error, result: null }
				else pushResult "assignments soon", error: null, result: _.filter(result, (a) -> a.deadline().date() < Date.today().addDays(7) and not a.finished() and new Date() < a.deadline())

	Session.set "loadMagsterInfoTimesCalled", time++
	return "dit geeft echt niets nuttig terug ofzo, als je dat denkt."