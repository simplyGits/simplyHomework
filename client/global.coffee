###*
# @method tasks
# @return {Object[]}
###
@tasks = -> # Also mix homework for tommorow and homework for days where the day before has no time. Unless today has no time.
	tasks = []
	#for gS in GoaledSchedules.find(dueDate: $gte: new Date).fetch()
	#	tasks.pushMore _.filter gS.tasks, (t) -> EJSON.equals t.plannedDate.date(), Date.today()

	res = []
	res = res.concat CalendarItems.find({
		'ownerId': Meteor.userId()
		'content': $exists: yes
		'content.type': 'homework'
		'content.description': $exists: yes
		'startDate': $gte: Date.today().addDays 1
		'endDate': $lte: Date.today().addDays 2
	}, {
		transform: (item) -> _.extend item,
			__id: item._id.toHexString()
			__taskDescription: item.content.description
			__className: Classes.findOne(item.classid)?.name ? ''
			__isDone: (d) ->
				if d? then CalendarItems.update item._id, $set: isDone: d
				item.isDone
	}).fetch()

	res = res.concat _.map tasks, (task) -> _.extend task,
		__id: task._id.toHexString()
		__taskDescription: task.content
		__className: '' # TODO: Should be set correctly.

	console.log 'getTasks result', res
	res

###*
# Get the classes for the current user, converted and sorted.
# @method classes
# @return {Cursor} A cursor pointing to the classes.
###
@classes = ->
	classInfos = Helpers.emboxValue -> Meteor.user()?.classInfos ? []
	Classes.find {
		_id: $in: (info.id for info in classInfos)
	}, {
		transform: classTransform
		sort: 'name': 1
	}

###*
# Get the projects for the current user, converted and sorted.
# @method projects
# @return {Cursor} A cursor pointing to the projects.
###
@projects = ->
	Projects.find {},
		transform: projectTransform
		sort:
			'deadline': 1
			'name': 1

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
@has = (feature) -> Helpers.emboxValue ->
	Meteor.user()?.premiumInfo?[feature]?.deadline > new Date()

@minuteTracker = new Tracker.Dependency
Meteor.startup ->
	$body = $ 'body'

	$("html").attr "lang", "nl"
	moment.locale "nl"
	emojione.ascii = yes # Convert ascii smileys (eg. :D) to emojis.

	reCAPTCHA.config
		theme: "light"
		publickey: "6LejzwQTAAAAAJ0blWyasr-UPxQjbm4SWOni22SH"

	window.viewportUnitsBuggyfill.init()

	if navigator.platform is 'Win32' or navigator.userAgent.indexOf('win') > -1
		$body.addClass 'win'

		if "ActiveXObject" of window
			$body.addClass 'ie'

	# Don't use `Meteor.user()` inside of a computation in here. Or expect a lot
	# of lag.
	Deps.autorun -> # User Login/Logout
		if Meteor.userId()?
			ga 'set', '&uid', Meteor.userId()
			followSetupPath()
		else
			NotificationsManager.hideAll()
			Router.go 'launchPage'

	window.onbeforeunload = ->
		NotificationsManager.hideAll()

		for x in $('input.messageInput').get()
			unless _.isEmpty x.value.trim()
				name = $(x)
					.closest('.chatWindow')
					.find('.name')
					.text()
					.split(' ')[0]
				return (
					if name? then "Je was een chatberichtje naar #{name} aan het typen! D:"
					else 'Je was een chatberichtje aan het typen! D:'
				)
		undefined

	Meteor.setInterval (-> minuteTracker.changed()), 60000
