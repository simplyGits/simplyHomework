@classes = ->
	homeworkItems.dep.depend()
	return Classes.find {_id: { $in: (cI.id for cI in (Meteor.user().classInfos ? [])) }},
		transform: classTransform
		sort: "name": 1

@projects = ->
	return Projects.find {},
		transform: projectTransform
		sort:
			"deadline": 1
			"name": 1

@magisterAppointmentTransform = (a) ->
	return a unless _.isObject a
	return ( @magisterAppointmentTransform x for x in a ) if _.isArray a

	a.__id = "#{a.id()}"
	a.__className = Helpers.cap(a.classes()[0]) if a.classes()[0]?

	a.__description = Helpers.convertLinksToAnchor a.content()
	a.__taskDescription = a.__description.replace /\n/g, "; "

	a.__groupInfo = _.find Meteor.user()?.profile.groupInfos, (gi) -> gi.group is a._description
	a.__class = a.__groupInfo?.id
	a.__classInfo = _.find Meteor.user()?.classInfos, (ci) -> EJSON.equals ci.id, a.__class

	return a

###*
# smoke weed everyday.
# @method kaas
###
@kaas = ->
	unless Meteor.user()?
		alertModal "swag", "420 blze it\nKaas FTW"
	else
		alertModal "swag", "420 blze it\nKaas FTW\n\ndo u even lift #{Meteor.user().profile.firstName}?"
	audio = new Audio
	audio.src = "/audio/smoke weed everyday.wav"
	audio.play()
	return "420 blaze cheese"

###*
# Checks if the current user (`Meteor.user()`) has the given
# premium `feature`.
# @method has
# @param feature {String} The feature to check for.
###
@has = (feature) ->
	try
		return Meteor.user().premiumInfo[feature].deadline > new Date()
	catch
		return no

###*
# Checks if the current user's browser is an old IE.
# @method isOldInternetExplorer
# @return {Array} 0: {Boolean} Whether or not the IE is old, 1: {Number|Null} The version of the current IE, if the user is not on IE; null.
###
isOldInternetExplorer = ->
	if navigator.appName is "Microsoft Internet Explorer"
		version = parseFloat RegExp.$1 if /MSIE ([0-9]{1,}[\.0-9]{0,})/.exec(navigator.userAgent)?
		return [ version < 9.0, version ]
	return [false, null]

@minuteTracker = new Tracker.Dependency
Meteor.startup ->
	window.viewportUnitsBuggyfill.init()
	NProgress.configure showSpinner: no
	[oldBrowser, version] = isOldInternetExplorer()

	if oldBrowser # old Internet Explorer versions don't even support fast-render with iron-router :')
		$("body").text ""
		Blaze.render Template.oldBrowser, $("body").get()[0]
		ga "send", "event", "reject",  "old-browser", "" + version
	else if "ActiveXObject" of window # Some css fixes for IE
		$("head").append "<style>.vCenter { position: relative !important } span#addProjectIcon { padding-right: 30px !important } div.backdrop { display: none; }</style>"

	# Some css fixes for Windows
	if navigator.appVersion.indexOf("Win") isnt -1
		$("head").append '<style>.robotoThin, .btn-trans { font-weight: 300 !important } * { -webkit-font-smoothing: initial !important }</style>'

	$.getScript "/js/advertisement.js" # adblock detection trick ;D

	unless Session.get "isPhone"
		Deps.autorun -> try UserStatus.startMonitor idleOnBlur: true

	interval = null
	Deps.autorun -> # User Login/Logout
		if Meteor.userId()?
			ga "set", "&uid", Meteor.userId()

			# Automagically update Magister info.
			interval ?= Meteor.setInterval ( ->
				initializeMagister yes if Meteor.status().connected
			), 1200000
		else
			for key in _.keys amplify.store() when key.indexOf("hardCachedAppointments") is 0
				amplify.store key, null

			resetMagister()

			Meteor.clearInterval interval
			interval = null

			NotificationsManager.hideAll()

	window.onbeforeunload = ->
		NotificationsManager.hideAll()

		for x in $("input.messageInput").get()
			if x.value.trim().length isnt 0
				name = $(x).closest(".chatWindow").find(".name").text().split(" ")[0]
				return (
					if name? then "Je was een chatberichtje naar #{name} aan het typen! D:"
					else "Je was een chatberichtje aan het typen! D:"
				)

	prevTime = _.now()
	Meteor.setInterval (->
		x = _.now()
		minuteTracker.changed() if x - prevTime >= 60000
		prevTime = x
	), 10000
