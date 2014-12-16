@homeworkItems = new ReactiveVar []
appointmentsTommorow = new ReactiveVar []
nextAppointmentToday = new ReactiveVar null
currentAppointment = new ReactiveVar null

getTasks = -> # Also mix homework for tommorow and homework for days where the day before has no time. Unless today has no time.
	tasks = _.flatten (gS.tasksForToday() for gS in GoaledSchedules.find(_homework: { $exists: true }, ownerId: Meteor.userId()).fetch())
	tmp = []
	for task in tasks
		tmp.push _.extend task,
			__id: task._id.toHexString()
			__taskDescription: "leer"
			#__chapter: Classes.findOne(task._parent.classId()).

	for homework in homeworkItems.get() then do (homework) ->
		tmp.push _.extend homework,
			__id: "#{homework.id()}"
			__name: Helpers.cap homework.classes()[0]
			__taskDescription: homework.content().replace(/\n/g, "; ")
			__className: if (val = homework.classes()[0])[0] is val[0].toUpperCase() then val else Helpers.cap val

	for calendarItem in CalendarItems.find(_ownerId: Meteor.userId()).fetch()
		tmp.push _.extend calendarItem,
			__id: calendarItem._id.toHexString()
			__taskDescription: calendarItem.description()
			__className: Classes.findOne(calendarItem.classId())?.name() ? ""
			isDone: (d) ->
				if d?
					CalendarItems.update calendarItem._id, $set: _isDone: d
					calendarItem._isDone = d
				else calendarItem._isDone

	return tmp

tasksAmount = -> getTasks().length

hasAppointments = -> appointmentsTommorow.get().length > 0 or _.any [nextAppointmentToday, currentAppointment], (x) -> x.get()?
Template.appOverview.helpers
	currentDate: -> DateToDutch()
	currentDay: -> DayToDutch()
	weekNumber: -> moment().week()
	tasksAmount: tasksAmount
	tasksWord: -> if tasksAmount() is 1 then "taak" else "taken"

	itemContainerMargin: ->
		d = 350
		if has "noAds" then d -= 90
		if not hasAppointments() then d -= 170
		return "#{d}px"

	tasks: getTasks
	projects: -> projects()

	foundAppointment: hasAppointments
	dayOver: -> not nextAppointmentToday.get()?

@originals = {}

Template.taskRow.events
	"change": (event) ->
		t = $ event.target
		checked = t.is(":checked")
		taskId = t.attr "taskid"
		
		@isDone checked
		homeworkItems.dep.changed()

		t.parent()
			.stop()
			.css(textDecoration: if checked then "line-through" else "initial")
			.velocity(opacity: if checked then .4 else 1)

Template.infoNextDay.helpers
	firstHour: -> appointmentsTommorow.get()[0].beginBySchoolHour()
	lastHour: -> _.last(appointmentsTommorow.get()).beginBySchoolHour()
	people: ->
		groupsTommorow = (x.group for x in _.filter Meteor.user().profile.groupInfos, (gi) -> _.any appointmentsTommorow.get(), (a) -> a.description() is gi.group)
		Meteor.defer -> $('[data-toggle="tooltip"]').tooltip() # Render the shit out of them
		return Meteor.users.find( {_id: { $ne: Meteor.userId() }, "profile.groupInfos": $elemMatch: group: $in: groupsTommorow}, {limit: 56} ).fetch()

Template.infoNextLesson.helpers
	hours: ->   val = nextAppointmentToday.get()?.begin().getHours()  ; if val? then Helpers.addZero(val) else ""
	minutes: -> val = nextAppointmentToday.get()?.begin().getMinutes(); if val? then ":#{Helpers.addZero(val)}" else ""
	appointment: -> nextAppointmentToday.get()

Template.infoCurrentLesson.helpers
	hours: ->   val = currentAppointment.get()?.end().getHours()  ; if val? then Helpers.addZero(val) else ""
	minutes: -> val = currentAppointment.get()?.end().getMinutes(); if val? then ":#{Helpers.addZero(val)}" else ""
	appointment: -> currentAppointment.get()

Template.appOverview.events
	"click #addProjectIcon": ->
		$("#projectNameInput").val ""
		$("#projectDescriptionInput").val ""
		$("#projectClassNameInput").val ""

		$("#addProjectModal").modal()

Template.appOverview.rendered = ->
	magisterResult "appointments tomorrow", (e, r) ->
		return if e?

		appointmentsTommorow.set _.filter r, (a) -> not a.fullDay() and a.classes().length > 0 and _.contains [5..19], a.begin().getHours()

	updateInterval = null
	magisterResult "appointments today", (e, r) ->
		return if e?

		clearInterval updateInterval if updateInterval?
		updateInterval = setInterval (do (r) ->
			nextAppointmentToday.set _.find r, (a) -> not a.fullDay() and new Date() < a.begin() and a.classes().length > 0
			currentAppointment.set _.find r, (a) -> not a.fullDay() and new Date() > a.begin() and new Date() < a.end() and a.classes().length > 0
		), 1000

	$("#currentDate > span").tooltip placement: "bottom", html: true, title: "<h4>Week: #{moment().week()}</h4>"

	unless Get.schedular()?.biasToday() is 0
		magisterResult "appointments this week", (error, result) ->
			return if error?

			date = switch Helpers.weekDay new Date()
				when 4 then Date.today().addDays(3)
				when 5 then Date.today().addDays(2)
				else Date.today().addDays(1)

			if new Date().getHours() < 4 and Helpers.weekDay(date) isnt 0 then date.addDays(-1)

			homework = _.where result, (a) -> a.content()? and a.content() isnt "" and a.begin().getTime() > new Date().getTime() and _.contains([1..5], a.infoType()) and a.classes().length > 0
			homeworkItems.set _.where homework, (h) -> EJSON.equals(date, h.begin().date()) or Get.schedular().schedularPrefs().bias(h.begin().addDays(-1, yes).date()) is 0