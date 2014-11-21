homeworkDependency = new Deps.Dependency
homeworkItems = []
firstAppointment = new ReactiveVar null

getTasks = -> # Also mix homework for tommorow and homework for days where the day before has no time. Unless today has no time.
	homeworkDependency.depend()

	tasks = _.flatten (gS.tasksForToday() for gS in GoaledSchedules.find(_homework: { $exists: true }, ownerId: Meteor.userId()).fetch())
	tmp = []
	for task in tasks
		tmp.push _.extend task,
			__id: task._id
			__taskDescription: "leer"
			#__chapter: Classes.findOne(task._parent.classId()).

	for homework in homeworkItems
		do (homework) ->
			tmp.push
				__id: homework.id()
				__taskDescription: homework.content().replace(/\n/g, "; ")
				__className: if (val = homework.classes()[0])[0] is val[0].toUpperCase() then val else Helpers.cap val

				isDone: homework.isDone
	return tmp

tasksAmount = -> if _.isFunction(getTasks) then getTasks().length else 0

Template.appOverview.helpers
	currentDate: -> DateToDutch()
	currentDay: -> DayToDutch()
	weekNumber: -> new Date().getWeek()
	tasksAmount: tasksAmount
	tasksWord: -> if tasksAmount() is 1 then "taak" else "taken"

	itemContainerMargin: -> if Meteor.user().hasPremium then "250px" else "350px"

	tasks: getTasks

@originals = {}

Template.taskRow.events
	"change": (event) ->
		checked = $(event.target).is(":checked")
		taskId = event.target.attributes["taskid"].value
		row = $ "[taskid=#{taskId}]"
		
		task = getTasks().smartFind Number(taskId), (t) -> t.__id
		task.isDone checked

		row.stop()
		# unless Session.get "isPhone"
		# 	if checked
		# 		originals[taskId] = row.find("span").html()
		# 		strikeThrough(row, 0)
		# 	else
		# 		row.find("span#stroke")
		# 			.css textDecoration: "initial"
		# 			.html originals[taskId]
		# else
		row.css textDecoration: if checked then "line-through" else "initial"
		row.velocity opacity: if checked then .4 else 1

Template.infoNextDay.helpers
	hours: -> firstAppointment.get().begin().getHours()
	minutes: -> firstAppointment.get().begin().getMinutes()

Template.appOverview.rendered = ->
	onMagisterInfoResult "appointments tomorrow", (e, r) ->
		return if e?

		firstAppointment.set _.find r, (a) -> not a.fullDay() and _.contains [5..19], a

	$("#currentDate > span").tooltip placement: "bottom", html: true, title: "<h4>Week: #{new Date().getWeek()}</h4>"

	unless Get.schedular()?.biasToday() is 0
		onMagisterInfoResult "appointments this week", (error, result) ->
			return if error?

			date = switch Helpers.weekDay new Date()
				when 4 then Date.today().addDays(3)
				when 5 then Date.today().addDays(2)
				else Date.today().addDays(1)

			if new Date().getHours() < 4 then date.addDays(-1)

			homework = _.where result, (a) -> a.content()? and a.content() isnt "" and a.begin().getTime() > new Date().getTime()
			homeworkItems = _.where homework, (h) -> EJSON.equals(date, h.begin().date()) or Get.schedular().schedularPrefs().bias(h.begin().addDays(-1, yes).date()) is 0

			homeworkDependency.changed()