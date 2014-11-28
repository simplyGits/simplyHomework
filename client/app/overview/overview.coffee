homeworkDependency = new Deps.Dependency
homeworkItems = new ReactiveVar []
firstAppointmentTomorrow = new ReactiveVar null
nextAppointmentToday = new ReactiveVar null
currentAppointment = new ReactiveVar null

getTasks = -> # Also mix homework for tommorow and homework for days where the day before has no time. Unless today has no time.
	homeworkDependency.depend()

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
	return tmp

tasksAmount = -> getTasks().length

Template.appOverview.helpers
	currentDate: -> DateToDutch()
	currentDay: -> DayToDutch()
	weekNumber: -> new Date().week()
	tasksAmount: tasksAmount
	tasksWord: -> if tasksAmount() is 1 then "taak" else "taken"

	itemContainerMargin: -> if Meteor.user().hasPremium then "250px" else "350px"

	tasks: getTasks

	foundAppointment: -> _.any [firstAppointmentTomorrow, nextAppointmentToday, currentAppointment], (x) -> x.get()?
	dayOver: -> not nextAppointmentToday.get()?

@originals = {}

Template.taskRow.events
	"change": (event) ->
		t = $ event.target
		checked = t.is(":checked")
		taskId = t.attr "taskid"
		
		task = _.find getTasks(), (t) -> t.__id is taskId
		task.isDone checked

		t.parent()
			.stop()
			.css(textDecoration: if checked then "line-through" else "initial")
			.velocity(opacity: if checked then .4 else 1)

Template.infoNextDay.helpers
	hours: ->   val = firstAppointmentTomorrow.get()?.begin().getHours()  ; if val? then Helpers.addZero(val) else ""
	minutes: -> val = firstAppointmentTomorrow.get()?.begin().getMinutes(); if val? then ":#{Helpers.addZero(val)}" else ""
	appointment: -> firstAppointmentTomorrow.get()

Template.infoNextLesson.helpers
	hours: ->   val = nextAppointmentToday.get()?.begin().getHours()  ; if val? then Helpers.addZero(val) else ""
	minutes: -> val = nextAppointmentToday.get()?.begin().getMinutes(); if val? then ":#{Helpers.addZero(val)}" else ""
	appointment: -> nextAppointmentToday.get()

Template.appOverview.rendered = ->
	onMagisterInfoResult "appointments tomorrow", (e, r) ->
		return if e?

		firstAppointmentTomorrow.set _.find r, (a) -> not a.fullDay() and _.contains [5..19], a.begin().getHours()

	updateInterval = null
	onMagisterInfoResult "appointments today", (e, r) ->
		return if e?

		clearInterval updateInterval if updateInterval?
		updateInterval = setInterval (do (r) ->
			nextAppointmentToday.set _.find r, (a) -> not a.fullDay() and new Date() < a.begin() and a.classes().length > 0
			currentAppointment.set _.find r, (a) -> not a.fullDay() and new Date() > a.begin() and new Date() < a.end()
		), 1000

	$("#currentDate > span").tooltip placement: "bottom", html: true, title: "<h4>Week: #{new Date().week()}</h4>"

	unless Get.schedular()?.biasToday() is 0
		onMagisterInfoResult "appointments this week", (error, result) ->
			return if error?

			date = switch Helpers.weekDay new Date()
				when 4 then Date.today().addDays(3)
				when 5 then Date.today().addDays(2)
				else Date.today().addDays(1)

			if new Date().getHours() < 4 then date.addDays(-1)

			homework = _.where result, (a) -> a.content()? and a.content() isnt "" and a.begin().getTime() > new Date().getTime() and _.contains([1..5], a.infoType()) and a.classes().length > 0
			homeworkItems.set _.where homework, (h) -> EJSON.equals(date, h.begin().date()) or Get.schedular().schedularPrefs().bias(h.begin().addDays(-1, yes).date()) is 0

			homeworkDependency.changed()