APPOINTMENT_INVALIDATION_TIME_MS = 1200000 # Time in ms after the appointment cache is invalidated. (currently: 20m)
APPOINTMENT_FORCED_UPDATE_TIME_MS = APPOINTMENT_INVALIDATION_TIME_MS + 600000 # Time in ms after the appointment cache is updated. (currently: 30m)

results = {}
callbacks = {}
currentlyFetching = []
magisterWaiters = []
appointmentPool = []
magisterLoaded = no
@magister = null

Deps.autorun => if Meteor.user()? then @hardCachedAppointments = amplify.store("hardCachedAppointments_#{Meteor.userId()}") ? []

@getHardCacheAppointments = (begin, end) ->
	x = _.filter (Appointment._convertStored @magister, a for a in hardCachedAppointments), (x) -> x.begin().date() >= begin.date() and x.end().date() <= end.date()
	return _.reject x, (a) -> a.id() isnt -1 and _.any(x, (z) -> z isnt a and z.begin() is a.begin() and z.end() is a.end() and z.description() is a.description())

setHardCacheAppointments = (data) ->
	for appointment in data
		_.remove hardCachedAppointments, (x) ->
			x = Appointment._convertStored(@magister, x)
			return "#{x.begin().getTime()}#{x.end().getTime()}" is "#{appointment.begin().getTime()}#{appointment.end().getTime()}"

		hardCachedAppointments.push appointment._makeStorable()

	_.remove hardCachedAppointments, (x) -> x._end < new Date().addDays(-7) or x._begin > new Date().addDays(14)
	amplify.store "hardCachedAppointments_#{Meteor.userId()}", JSON.decycle(hardCachedAppointments), expires: 432000000

###*
# Returns appointments withing the given date range. Using caching systems.
#
# @method magisterAppointment
# @param from {Date} The start date for the Appointments, you won't get appointments from before this date.
# @param [to] {Date} The end date for the Appointments, you won't get appointments from after this date.
# @param [download=yes] {Boolean} Whether or not to download the full user objects from the server.
# @param [disallowHardCache=yes] {Boolean} If true the hardcache will not be used (use this to prevent your callback being called 2 times in rapid fashion).
# @param callback {Function} A standard callback.
# 	@param [callback.error] {Object} The error, if it exists.
# 	@param [callback.result] {Appointment[]} An array containing the Appointments.
# @return {Boolean} Returns true if all asked appointments are in cache.
###
@magisterAppointment = ->
	callback = _.find arguments, (a) -> _.isFunction a
	[download, disallowHardCache] = _.filter(arguments, (a) -> _.isBoolean a)
	[from, to] = _.where arguments, (a) -> _.isDate a

	download ?= no; disallowHardCache ?= no

	dates = []
	if to is from or not _.isDate to
		dates = [from]
	else for i in [0..moment(to).diff from, "days"]
		dates.push moment(from).add(i, "days").toDate()
	dates = (d.date() for d in dates)

	result = []

	prefetchedAppointmentInfos = _.filter appointmentPool, (x) -> (_.now() - x.setTime) < APPOINTMENT_INVALIDATION_TIME_MS and _.any dates, (d) -> EJSON.equals x.date, d
	for ai in prefetchedAppointmentInfos
		_.remove dates, (d) -> EJSON.equals ai.date, d

		result.pushMore ai.appointments

	if dates.length is 0
		callback null, result, yes
		return

	_.defer ->
		unless disallowHardCache
			callback null, getHardCacheAppointments dates[0], _.last(dates)

		NProgress.start()
		magisterObj (m) -> m.appointments dates[0], _.last(dates), download, (e, r) ->
			if e?
				callback e, null, yes
				return

			for date in dates
				oldAi = _.find((ai) -> EJSON.equals ai.date, date)

				clearInterval oldAi?._interval
				oldAi?._invalidationComputation.stop?()

				invalidationDependency = oldAi?.invalidationDependency
				invalidationDependency ?= new Tracker.Dependency

				_.remove appointmentPool, (ai) -> EJSON.equals ai.date, date
				appointmentPool.push ai = {
					_interval: null
					_invalidationComputation: null

					appointments: _.filter r, (a) -> EJSON.equals a.begin().date(), date
					setTime: _.now()
					invalidationDependency: invalidationDependency
					date
				}

				ai._invalidationComputation = Tracker.autorun -> # Recall any dependents if we have an connection.
					if (_.now() - ai.setTime) >= APPOINTMENT_FORCED_UPDATE_TIME_MS and Meteor.status().connected
						invalidationDependency.changed()

				ai._interval = setInterval (->
					ai._invalidationComputation.invalidate()
				), APPOINTMENT_FORCED_UPDATE_TIME_MS # Invalidate the computatation.

				_.remove result, (a) -> EJSON.equals a.begin().date(), date # Clear already cached data put in result.

			result.pushMore r
			setHardCacheAppointments result
			callback null, result
			NProgress.done()

	return dates.length is prefetchedAppointmentInfos.length # Returns true if all asked appointments are in cache.

###*
# Returns appointments withing the given date range. Using caching systems.
# This function will also keep the appointments updated each 30 minutes.
#
# @method updateAppointments
# @param from {Date} The start date for the Appointments, you won't get appointments from before this date.
# @param [to] {Date} The end date for the Appointments, you won't get appointments from after this date.
# @param [download=yes] {Boolean} Whether or not to download the full user objects from the server.
# @return {ReactiveVar} A ReactiveVar containg an array with the appointments in the given date range.
###
@updatedAppointments = ->
	download = _.find(arguments, (a) -> _.isBoolean a) ? no
	[from, to] = _.where arguments, (a) -> _.isDate a

	res = new ReactiveVar []
	magisterAppointment from, to, download, (e, r) ->
		if e? then callback e, null
		else res.set r

	dates = []
	if to is from or not _.isDate to
		dates = [from]
	else for i in [0..moment(to).diff from, "days"]
		dates.push moment(from).add(i, "days").toDate()

	appointmentInfos = _.filter appointmentPool, (x) -> _.any dates, (d) -> EJSON.equals x.date, d.date()
	for ai in appointmentInfos
		ai.invalidationDependency.depend()

	return res

loaders =
	"classes": (m, cb) ->
		magisterResult "course", (e, r) ->
			if e? then cb e, null
			else r.classes (error, result) -> cb error, result

pushResult = (name, result) ->
	check name, String

	results[name] = result
	callback(result.error, result.result) for callback in (callbacks[name]?.callbacks ? [])
	callbacks[name]?.dependency.changed()

@magisterResult = (name, callback) ->
	# If callback is null, it will use a tracker to rerun computations, otherwise it will just recall the given callback.
	check name, String
	check callback, Match.Optional Function

	callbacks[name] ?= { callbacks: [], dependency: new Tracker.Dependency }
	if callback? then callbacks[name].callbacks.push callback
	else callbacks[name].dependency.depend()

	if (result = results[name])?
		callback? result.error, result.result
		return result
	else if not _.contains(currentlyFetching, name) and (val = loaders[name])?
		currentlyFetching.push name

		cb = (m) -> val m, (error, result) ->
			_.remove currentlyFetching, name
			pushResult name, { error, result }

		if magister? then cb magister
		else magisterWaiters.push cb

	return error: null, result: null

@resetMagister = ->
	results = {}
	callbacks = {}
	currentlyFetching = []
	@magister = null

@magisterObj = (cb) ->
	if magisterLoaded then cb magister
	else magisterWaiters.push cb

@initializeMagister = (force = no) ->
	check force, Boolean
	return if not force and @magister?

	try
		url = Schools.findOne(Meteor.user().profile.schoolId).url
	catch
		console.warn "Couldn't retreive school info!"
		return

	school = Schools.findOne(Meteor.user().profile.schoolId)
	unless Meteor.user().profile.schoolId?
		console.warn "User has no school info."
		return
	else unless school?
		console.warn "Can't find the school of the user in the database."
		return

	else unless Meteor.user().magisterCredentials?
		console.warn "User has no magisterCredentials."
		return

	{ username, password } = Meteor.user().magisterCredentials

	(@magister = new Magister(school, username, password, no)).ready (err) ->
		if err?
			notify("Kan niet met Magister verbinden.", "error", -1, yes, 9)
			return

		magisterLoaded = yes
		cb @ for cb in magisterWaiters
		magisterWaiters = []

		@courses (e, r) ->
			if e?
				pushResult "course", { error: e, result: null }
				pushResult "grades", { error: e, result: null }
			else
				r[0].grades no, (error, result) -> pushResult "grades", { error, result }
				pushResult "course", { error: null, result: r[0] }

		@assignments no, yes, (error, result) ->
			pushResult "assignments", { error, result }
			if error? then pushResult "assignments soon", { error, result: null }
			else pushResult "assignments soon", error: null, result: _.filter(result, (a) -> a.deadline().date() < Date.today().addDays(7) and not a.finished() and new Date() < a.deadline())

		@studyGuides (error, result) ->
			if error? then pushResult "studyGuides", { error, result: null }
			else
				left = result.length
				push = -> if --left is 0 then pushResult "studyGuides", { error: null, result }

				for studyGuide in result then do (studyGuide) ->
					studyGuide.parts (e, r) ->
						studyGuide.parts = r ? []
						push()

	return "dit geeft echt niets nuttig terug ofzo, als je dat denkt."
