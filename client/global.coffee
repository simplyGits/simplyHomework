###*
# @method tasks
# @return {Object[]}
###
@tasks = ->
	# TODO: Also mix homework for tommorow and homework for days where the day
	# before has no time. Unless today has no time.

	tasks = []
	#for gS in GoaledSchedules.find(dueDate: $gte: new Date).fetch()
	#	tasks.pushMore _.filter gS.tasks, (t) -> EJSON.equals t.plannedDate.date(), Date.today()

	res = []
	res = res.concat CalendarItems.find({
		'userIds': Meteor.userId()
		'content': $exists: yes
		'content.type': $ne: 'information'
		'content.description': $exists: yes
		'startDate': $gte: Date.today().addDays 1
		'endDate': $lte: Date.today().addDays 2
	}, {
		sort:
			startDate: 1
		transform: (item) -> _.extend item,
			__id: item._id
			__taskDescription: item.content.description
			__className: Classes.findOne(item.classId)?.name ? ''
			__isDone: (d) ->
				if d?
					CalendarItems.update item._id, (
						if d then $push: usersDone: Meteor.userId()
						else $pull: usersDone: Meteor.userId()
					)
				Meteor.userId() in item.usersDone
	}).fetch()

	res = res.concat _.map tasks, (task) -> _.extend task,
		__id: task._id.toHexString()
		__taskDescription: task.content
		__className: '' # TODO: Should be set correctly.

	console.log 'getTasks result', res
	res

###*
# @method tasksCount
# @return {Object}
###
@tasksCount = ->
	return total: 0, finished: 0, unfinished: 0
	Helpers.emboxValue ->
		console.trace 'invalidate taskCount()'
		tasks = @tasks()
		finishedTasks = _.filter tasks, (t) -> t.__isDone()

		total: tasks.length
		finished: finishedTasks.length
		unfinished: tasks.length - finishedTasks.length

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
	moment.locale "nl"
	emojione.ascii = yes # Convert ascii smileys (eg. :D) to emojis.

	reCAPTCHA.config
		theme: "light"
		publickey: "6LejzwQTAAAAAJ0blWyasr-UPxQjbm4SWOni22SH"

	if navigator.platform is 'Win32' or navigator.userAgent.indexOf('win') > -1
		$body.addClass 'win'

		if 'ActiveXObject' of window
			$body.addClass 'ie'

	Tracker.autorun ->
		if Meteor.userId()? # login
			runSetup()
			localStorage['appUsedBefore'] = yes

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
