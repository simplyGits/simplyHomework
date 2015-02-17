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

###*
# Fetches event like objects from various places and converts them in an FullCalendar supporting manner.
# CANIDATE FOR NOT FINISHING. ;)
#
# @method events
# @return {ReactiveVar} A ReactiveVar containing an event[].
###
@events = null

@magisterAppointmentTransform = (a) ->
	return a unless _.isObject a
	return ( @magisterAppointmentTransform x for x in a ) if _.isArray a

	a.__id = "#{a.id()}"
	a.__className = Helpers.cap(a.classes()[0]) if a.classes()[0]?

	# Find URLs and place them in an anchor tag.
	a.__description = a.content().replace(/&amp;/ig, "&").replace /[-a-zA-Z0-9@:%_\+.~#?&//=]{2,256}\.[a-z]{2,4}\b((\/|\?)[-a-zA-Z0-9@:%_\+.~#?&//=]+)?\b/ig, (match) ->
		if /^https?:\/\/.+/i.test match
			return "<a target=\"_blank\" href=\"#{match}\">#{match}</a>"
		else
			return "<a target=\"_blank\" href=\"http://#{match}\">#{match}</a>"
	a.__taskDescription = a.__description.replace /\n/g, "; "

	a.__groupInfo = _.find Meteor.user()?.profile.groupInfos, (gi) -> gi.group is a._description
	a.__class = a.__groupInfo?.id
	a.__classInfo = _.find Meteor.user()?.classInfos, (ci) -> EJSON.equals ci.id, a.__class

	return a

@kaas = ->
	unless Meteor.user()?
		alertModal "swag", "420 blze it\nKaas FTW"
	else
		alertModal "swag", "420 blze it\nKaas FTW\n\ndo u even lift #{Meteor.user().profile.firstName}?"
	audio = new Audio
	audio.src = "/audio/smoke weed everyday.wav"
	audio.play()
	return "420 blaze cheese"

@has = (feature) ->
	try
		return Meteor.user().premiumInfo[feature].deadline > new Date()
	catch
		return no

isOldInternetExplorer = ->
	if navigator.appName is "Microsoft Internet Explorer"
		version = parseFloat RegExp.$1 if /MSIE ([0-9]{1,}[\.0-9]{0,})/.exec(navigator.userAgent)?
		return [ version < 9.0, version ]
	return false

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
		if Meteor.user()?
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

			NotificationsManager.hideAll()

	prevTime = _.now()
	Meteor.setInterval (->
		x = _.now()
		minuteTracker.changed() if x - prevTime >= 60000
		prevTime = x
	), 10000
