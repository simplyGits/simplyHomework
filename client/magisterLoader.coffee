APPOINTMENT_INVALIDATION_TIME_MS = 1200000 # Time in ms after the appointment cache is invalidated. (currently: 20m)
APPOINTMENT_FORCED_UPDATE_TIME_MS = APPOINTMENT_INVALIDATION_TIME_MS + 600000 # Time in ms after the appointment cache is updated. (currently: 30m)

results = {}
callbacks = {}
currentlyFetching = []
magisterWaiters = []
appointmentPool = []
magisterLoaded = no
@magister = null

Deps.autorun => if Meteor.userId()? then @hardCachedAppointments = amplify.store("hardCachedAppointments_#{Meteor.userId()}") ? []

@getHardCacheAppointments = (begin, end) ->
	return unless @hardCachedAppointments?
	x = _.filter (Appointment._convertStored @magister, a for a in @hardCachedAppointments), (x) -> x.begin().date() >= begin.date() and x.end().date() <= end.date()
	return _.reject x, (a) -> a.id() isnt -1 and _.any(x, (z) -> z isnt a and z.begin() is a.begin() and z.end() is a.end() and z.description() is a.description())

setHardCacheAppointments = (data) ->
	return unless @hardCachedAppointments?
	for appointment in data
		_.remove @hardCachedAppointments, (x) ->
			x = Appointment._convertStored(@magister, x)
			return "#{x.begin().getTime()}#{x.end().getTime()}" is "#{appointment.begin().getTime()}#{appointment.end().getTime()}"

		@hardCachedAppointments.push appointment._makeStorable()

	_.remove @hardCachedAppointments, (x) -> x._end < new Date().addDays(-7) or x._begin > new Date().addDays(14)
	amplify.store "hardCachedAppointments_#{Meteor.userId()}", JSON.decycle(@hardCachedAppointments), expires: 432000000

###*
# [Reactive]
#
# Returns appointments withing the given date range. Using caching systems.
# Should be run in an reactive enviroment, otherwise it's posible this method
# will return an empty array.
#
# @method magisterAppointment
# @param from {Date} The start date for the Appointments, you won't get appointments from before this date.
# @param [to=from] {Date} The end date for the Appointments, you won't get appointments from after this date.
# @param [download=no] {Boolean} Whether or not to download the full user objects from the server.
# @return {Array} The appointments as array.
###
@magisterAppointment = ->
	[download, transform] = _.where arguments, (a) -> _.isBoolean a
	[from, to] = _.where arguments, (a) -> _.isDate a

	download ?= no
	transform ?= yes

	dates = []
	if to is from or not _.isDate to
		dates = [from]
	else for i in [0..moment(to).diff from, "days"]
		dates.push moment(from).add(i, "days").toDate()
	dates = (d.date() for d in dates)

	result = []
	count = 0

	for date in dates
		ai = appointmentPool["#{date.getTime()}"]

		if not ai?
			appointmentPool["#{date.getTime()}"] = ai =
				appointments: new ReactiveVar []
				invalidationTime: _.now() + APPOINTMENT_INVALIDATION_TIME_MS
				fetching: no

			result.pushMore getHardCacheAppointments date, date

		else if ai.fetching or ai.invalidationTime > _.now() then count++

		# When there was an `ai` found but it was invalidated we should just
		# download the appointments but not create a whole new pool item for it.
		# When we do that we still show the old info but update it shortly.

		ai.fetching = yes
		result.pushMore ai.appointments.get()

	if count isnt dates.length
		magisterObj (m) -> m.appointments dates[0], _.last(dates), download, (e, r) ->
			for date in dates
				ai = appointmentPool["#{date.getTime()}"]

				ai.invalidationTime = _.now() + APPOINTMENT_INVALIDATION_TIME_MS
				ai.fetching = no
				ai.appointments.set _.filter r, (a) -> EJSON.equals a.begin().date(), date

			setHardCacheAppointments r

	return if transform then magisterAppointmentTransform(result) else result

###*
# Returns appointments within the given date range. Using caching systems.
# This function will also keep the appointments updated each 30 minutes.
#
# @method updateAppointments
# @param from {Date} The start date for the Appointments, you won't get appointments from before this date.
# @param [to] {Date} The end date for the Appointments, you won't get appointments from after this date.
# @param [download=yes] {Boolean} Whether or not to download the full user objects from the server.
# @return {Array} An array containing the appointments.
###
@updatedAppointments = ->
	comp = Tracker.currentComputation
	handle = setTimeout (-> comp.invalidate()), APPOINTMENT_FORCED_UPDATE_TIME_MS
	comp.onInvalidate -> clearTimeout handle

	return magisterAppointment arguments...

loaders =
	"classes": (m, cb) ->
		magisterResult "course", (e, r) ->
			if e? then cb e, null
			else r.classes (error, result) -> cb error, result

	"grades": (m, cb) ->
		magisterResult "course", (e, r) ->
			if e? then cb e, null
			else r.grades no, no, (error, result) -> cb error, result

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
			if e? then pushResult "course", { error: e, result: null }
			else
				r[0].grades no, yes, yes, (error, result) -> pushResult "recent grades", { error, result }
				pushResult "course", { error: null, result: r[0] }

	return "dit geeft echt niets nuttig terug ofzo, als je dat denkt."
