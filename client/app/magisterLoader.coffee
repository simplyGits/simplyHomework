@results = {}
@callbacks = {}
@magisterInfoLoaded = no

pushResult = (name, result) ->
	check name, String

	results[name] = result
	callback(result.error, result.result) for callback in callbacks[name] ? []

@onMagisterInfoResult = (name, callback) ->
	check name, String
	check callback, Function

	callbacks[name] ?= []
	callbacks[name].push callback

	if (result = results[name])?
		callback result.error, result.result
		return result

@loadMagisterInfo = ->
	@magisterInfoLoaded = yes
	url = "https://#{Schools.findOne(Meteor.user().profile.schoolId).url()}"
	credentials = Meteor.user().magisterCredentials

	new Magister({ url }, credentials.username, credentials.password).ready (magister) ->
		magister.appointments new Date().addDays(-7), new Date().addDays(7), (error, result) -> pushResult "appointments", { error, result }

	return "dit geeft echt niets nuttig terug ofzo, als je dat denkt."