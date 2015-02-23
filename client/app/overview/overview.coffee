@homeworkItems = new ReactiveVar []
appointmentsTommorow = new ReactiveVar []
nextAppointmentToday = new ReactiveVar null
currentAppointment = new ReactiveVar null

getTasks = -> # Also mix homework for tommorow and homework for days where the day before has no time. Unless today has no time.
	tasks = []
	for gS in GoaledSchedules.find(dueDate: $gte: new Date).fetch()
		tasks.pushMore _.filter gS.tasks, (t) -> EJSON.equals t.plannedDate.date(), Date.today()

	tmp = []
	for task in tasks
		tmp.push _.extend task,
			__id: task._id.toHexString()
			__taskDescription: task.content
			__className: "" # Should be set correctly.

	tmp.pushMore homeworkItems.get()

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
	inLesson: -> currentAppointment.get()?

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
		return [] if Session.get "isPhone"
		subs.subscribe "usersData"
		groupsTommorow = (x.group for x in _.filter Meteor.user().profile.groupInfos, (gi) -> _.any appointmentsTommorow.get(), (a) -> a.description() is gi.group)
		Meteor.defer -> $('[data-toggle="tooltip"]').tooltip container: ".overviewImportantContainer" # Render the shit out of them
		return Meteor.users.find(_id: { $ne: Meteor.userId() }, "profile.groupInfos": $elemMatch: group: $in: groupsTommorow).fetch()

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
	@autorun ->
		minuteTracker.depend()

		today = magisterAppointment new Date()
		tommorow = magisterAppointment new Date().addDays 1

		appointmentsTommorow.set _.filter tommorow, (a) -> not a.fullDay() and a.classes().length > 0 and _.contains [5..19], a.begin().getHours()

		nextAppointmentToday.set _.find today, (a) -> not a.fullDay() and new Date() < a.begin() and a.classes().length > 0
		currentAppointment.set _.find today, (a) -> not a.fullDay() and new Date() > a.begin() and new Date() < a.end() and a.classes().length > 0

		$("#currentDate > span").tooltip placement: "bottom", html: true, title: "<h4>Week: #{moment().week()}</h4>"

	@autorun ->
		return if Get.schedular()?.biasToday() is 0
		grades = magisterResult("grades").result ? []

		date = switch Helpers.currentDay()
			when 4 then Date.today().addDays 3
			when 5 then Date.today().addDays 2
			else Date.today().addDays 1

		appointments = magisterAppointment new Date(), new Date().addDays(7)
		homework = _.filter appointments, (a) -> a.infoTypeString() is "homework" and a.content().length > 0 and a.classes().length > 0

		homeworkItems.set _.filter homework, (h) ->
			nextSchoolDay = EJSON.equals h.begin().date(), date
			noTimeDayInfront = no
			try noTimeDayInfront = Get.schedular().schedularPrefs.bias(h.begin().addDays(-1, yes).date()) is 0

			if nextSchoolDay or noTimeDayInfront then return yes
			else # now. For the real stuff...
				magisterId = h.__classInfo?.magisterId

				gradesCurrentClass = _(grades)
					.filter (g) -> g.class().id() is magisterId
					.forEach (g) -> g._grade = gradeConverter g._grade
					.value()

				endGrade = _.find gradesCurrentClass, (g) -> g.type().header()?.toLowerCase() is "e-jr"
				endGrade ?= _.find gradesCurrentClass, (g) -> g.type().header()?.toLowerCase() is "eind"
				endGrade ?= _.find gradesCurrentClass, (g) -> g.type().type() is 2

				lastGrade = _(gradesCurrentClass)
					.filter (g) -> g.type().type() isnt 2
					.max "_dateFilledIn"

				parsedData = Parser.parseDescription h.content()
				exercises = _(parsedData.exerciseData)
					.map (d) -> d.values
					.flatten()
					.value()

				exerciseData = calculateExercisePriority endGrade, lastGrade, exercises.length

				return _.now() > h.begin().date().addDays(-exerciseData.daysInfront).getTime()
