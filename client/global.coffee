###*
# Get the classes for the current user, converted and sorted.
# @method classes
# @return {Cursor} A cursor pointing to the classes.
###
@classes = ->
	console?.trace? 'classes()'
	Classes.find {
		_id: $in: (
			_(getClassInfos())
				.reject 'hidden'
				.pluck 'id'
				.value()
		)
	}, sort: 'name': 1

###*
# smoke weed everyday.
# @method kaas
# @return {String} SURPRISE MOTHERFUCKER
###
@kaas = ->
	alertModal 'swag', (
		if Meteor.userId()?
			"420 blze it\nKaas FTW\n\ndo u even lift #{Meteor.user().profile.firstName}?"
		else
			'420 blze it\nKaas FTW'
	)
	audio = new Audio
	audio.src = '/audio/smoke weed everyday.wav'
	audio.play()
	'420 blaze cheese'

###*
# Checks if the current user (`Meteor.user()`) has the given
# premium `feature`.
# @method has
# @param feature {String} The feature to check for.
# @return {Boolean}
###
@has = (feature) ->
	deadline = getUserField Meteor.userId(), "premiumInfo.#{feature}.deadline"
	deadline > new Date

@minuteTracker = new Tracker.Dependency
@dateTracker = new Tracker.Dependency
Meteor.startup ->
	$body = $ 'body'

	$("html").attr "lang", "nl"
	emojione.ascii = yes # Convert ascii smileys (eg. :D) to emojis.

	reCAPTCHA.config
		theme: 'light'
		sitekey: '6LejzwQTAAAAAJ0blWyasr-UPxQjbm4SWOni22SH'
		size: 'normal'

	if navigator.platform is 'Win32' or navigator.userAgent.indexOf('win') > -1
		$body.addClass 'win'

		if 'ActiveXObject' of window
			$body.addClass 'ie'

	nonLoginRoutes = [
		'login'
		'signup'
		'verifyMail'
		'forgotPass'
		'resetPass'
	]
	Tracker.autorun ->
		if Meteor.userId()? # login
			runSetup()
		else if FlowRouter.getRouteName() not in nonLoginRoutes
			Meteor.defer -> document.location.href = 'https://simplyhomework.nl/'

		expireDate = new Date localStorage.getItem 'Meteor.loginTokenExpires'
		document.cookie = "loggedIn=#{if Meteor.userId()? then '1' else '0'};path=/;domain=.simplyHomework.nl;expires=#{expireDate.toGMTString()}"

	console.log 'global() deviceType', Session.get 'deviceType'

	unless Session.equals 'deviceType', 'desktop'
		document.addEventListener 'visibilitychange', ->
			if document.hidden then Meteor.disconnect()
			else Meteor.reconnect()

	window.onbeforeunload = ->
		NotificationsManager.hideAll()
		undefined

	prevDate = new Date().getDate()
	Meteor.setInterval (->
		minuteTracker.changed()

		currentDate = new Date().getDate()
		if prevDate isnt currentDate
			prevDate = currentDate
			dateTracker.changed()
	), 60000
