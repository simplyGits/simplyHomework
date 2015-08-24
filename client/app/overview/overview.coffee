appointmentsTommorow = new ReactiveVar []
nextAppointmentToday = new ReactiveVar null
currentAppointment = new ReactiveVar null

hasAppointments = ->
	_.any([currentAppointment, nextAppointmentToday], (x) -> x.get()?) or
	appointmentsTommorow.get().length > 0

Template.appOverview.helpers
	currentDate: -> DateToDutch()
	currentDay: -> DayToDutch()
	weekNumber: -> moment().week()
	tasksAmount: -> tasks().length
	tasksWord: -> if tasks().length is 1 then 'taak' else 'taken'

	itemContainerMargin: ->
		margin = 350
		margin -= 90 if has 'noAds'
		margin -= 170 unless hasAppointments()
		"#{margin}px"

	tasks: -> tasks()
	projects: -> projects()

	foundAppointment: hasAppointments
	dayOver: -> not nextAppointmentToday.get()?
	inLesson: -> currentAppointment.get()?

@originals = {}

Template.taskRow.events
	'change': (event) ->
		$target = $ event.target
		checked = $target.is ':checked'

		@__isDone checked

		#$target.parent()
		#	.stop()
		#	.css textDecoration: if checked then 'line-through' else 'initial'
		#	.velocity opacity: if checked then .4 else 1

Template.infoNextDay.helpers
	firstHour: -> appointmentsTommorow.get()[0].beginBySchoolHour()
	lastHour: -> _.last(appointmentsTommorow.get()).beginBySchoolHour()
	people: ->
		return [] if Session.get 'isPhone'
		groupsTommorow = _(Meteor.user().profile.groupInfos)
			.filter (info) -> _.any appointmentsTommorow.get(), (a) -> a.description is info.group
			.pluck 'group'
			.value()

		Meteor.defer -> $('[data-toggle="tooltip"]').tooltip container: '.overviewImportantContainer' # Render the shit out of them

		Meteor.users.find(
			_id: $ne: Meteor.userId()
			'profile.groupInfos': $elemMatch: group: $in: groupsTommorow
		).fetch()

Template.infoNextLesson.helpers
	hours: ->   val = nextAppointmentToday.get()?.begin().getHours()  ; if val? then Helpers.addZero(val) else ""
	minutes: -> val = nextAppointmentToday.get()?.begin().getMinutes(); if val? then ":#{Helpers.addZero(val)}" else ""
	appointment: -> nextAppointmentToday.get()

Template.infoCurrentLesson.helpers
	hours: ->   val = currentAppointment.get()?.end().getHours()  ; if val? then Helpers.addZero(val) else ""
	minutes: -> val = currentAppointment.get()?.end().getMinutes(); if val? then ":#{Helpers.addZero(val)}" else ""
	appointment: -> currentAppointment.get()

Template.appOverview.events
	'click #addProjectIcon': -> showModal 'addProjectModal'

Template.appOverview.onRendered ->
	@subscribe 'externalCalendarItems', new Date(), new Date().addDays 1

	@autorun ->
		minuteTracker.depend()

		today = CalendarItems.find(
			ownerId: Meteor.userId()
			startdate:
				$gte: Date.today()
				$in: [5..19]
			endDate: $lte: Date.today().addDays 1
			classId: $exists: yes
		).fetch()
		tomorrow = CalendarItems.find(
			ownerId: Meteor.userId()
			startdate:
				$gte: Date.today().addDays 1
				$in: [5..19]
			endDate: $lte: Date.today().addDays 2
			classId: $exists: yes
		).fetch()

		currentAppointment.set _.find today, (a) -> a.startDate < new Date() and s.endDate > new Date()
		nextAppointmentToday.set _.find today, (a) -> new Date() < a.startDate
		appointmentsTommorow.set tomorrow

		$('#currentDate > span').tooltip
			placement: 'bottom'
			html: true
			title: "<h4>Week: #{moment().week()}</h4>"

	###
	@autorun ->
		# TODO: REFACTOR THE SHIT OUT OF THIS.
		return

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
				magisterId = h.__classInfo()?.magisterId

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
				lastGrade = null if lastGrade is -Infinity # rip lodash beheviour.

				parsedData = Parser.parseDescription h.content()
				exercises = _(parsedData.exerciseData)
					.map (d) -> d.values
					.flatten()
					.value()

				endGrade = gradeConverter endGrade?.grade()
				lastGrade = gradeConverter lastGrade?.grade()

				exerciseData = calculateExercisePriority endGrade, lastGrade, exercises.length

				return Date.today() >= h.begin().date().addDays(-exerciseData.daysInfront) and h.begin().date() > Date.today()
	###
