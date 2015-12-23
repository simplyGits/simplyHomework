@notices = notices = new Mongo.Collection null

recentGrades = ->
	dateTracker.depend()
	date = Date.today().addDays -4
	Grades.find(
		dateFilledIn: $gte: date
		isEnd: no
	).fetch()

Template.overview.helpers
	notices: ->
		notices.find {},
			sort: priority: -1
			transform: (n) -> _.extend n,
				clickable: if n.onClick? then 'clickable' else ''

	timeGreeting: TimeGreeting

	currentDate: DateToDutch
	currentDay: DayToDutch
	weekNumber: -> moment().week()

	itemContainerMargin: ->
		margin = 260
		margin -= 170 unless hasAppointments()
		"#{margin}px"

	projects: -> projects()

@originals = {}

Template.recentGrades.helpers
	gradeGroups: ->
		grades = recentGrades()
		_(grades)
			.sortByOrder 'dateFilledIn', 'desc'
			.uniq 'classId'
			.map (g) ->
				class: g.class()
				grades: (
					_(grades)
						.filter (x) -> x.classId is g.classId
						.sortBy 'dateFilledIn'
						.map (x) -> if x.passed then x.__grade else "<b style='color: red'>#{x.__grade}</b>"
						.join ' & '
				)
			.value()

Template.recentGradeGroup.events
	'click': -> FlowRouter.go 'classView', id: @class._id

Template.tasks.helpers
	tasks: -> tasks()

Template.taskRow.events
	'change': (event) ->
		$target = $ event.target
		checked = $target.is ':checked'

		@__isDone checked

		#$target.parent()
		#	.stop()
		#	.css textDecoration: if checked then 'line-through' else 'initial'
		#	.animate opacity: if checked then .4 else 1

Template.infoNextDay.helpers
	firstHour: -> _.first(appointmentsTommorow.get()).schoolHour
	lastHour: -> _.last(appointmentsTommorow.get()).schoolHour

Template.infoCurrentAppointment.helpers
	timeLeft: ->
		minuteTracker.depend()
		Helpers.timeDiff new Date(), @endDate

Template.infoNextLesson.helpers
	timeLeft: ->
		minuteTracker.depend()
		Helpers.timeDiff new Date(), @startDate

Template.overview.events
	'click .notice': ->
		a = @onClick
		switch a?.action
			when 'route' then FlowRouter.go a.route, a.params, a.queryParams

	'click #addProjectIcon': -> showModal 'addProjectModal'

Template.overview.onCreated ->
	@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 4
	@subscribe 'externalGrades', onlyRecent: yes

	@autorun ->
		if recentGrades().length
			notices.upsert {
				template: 'recentGrades'
			}, {
				template: 'recentGrades'
				header: 'Recent behaalde cijfers'
				priority: 0
			}
		else
			notices.remove template: 'recentGrades'

	@autorun ->
		if tasks().length
			notices.upsert {
				template: 'tasks'
			}, {
					template: 'tasks'
					header: 'Nu te doen'
					priority: 1
			}
		else
			notices.remove template: 'tasks'

	notified = []
	@autorun ->
		return # TODO: doe hier iets mee.
		minuteTracker.depend()
		nextAppointment = CalendarItems.findOne {
			userIds: Meteor.userId()
			startDate: $gte: new Date
			scrapped: false
			schoolHour:
				$exists: yes
				$ne: null
		}, sort: 'startDate': 1
		if nextAppointment?
			timeDiff = nextAppointment.startDate - _.now()

			if timeDiff <= 600000 and nextAppointment._id not in notified
				new Notification "#{nextAppointment.class().name} start in #{~~(timeDiff / 1000 / 60)} minuten"
				notified.push nextAppointment._id

	@autorun ->
		minuteTracker.depend()

		today = CalendarItems.find({
			userIds: Meteor.userId()
			startDate: $gte: Date.today()
			endDate: $lte: Date.today().addDays 1
			scrapped: false
			schoolHour:
				$exists: yes
				$ne: null
		}, sort: 'startDate': 1).fetch()
		tomorrow = CalendarItems.find({
			userIds: Meteor.userId()
			startDate: $gte: Date.today().addDays 1
			endDate: $lte: Date.today().addDays 2
			scrapped: false
			schoolHour:
				$exists: yes
				$ne: null
		}, sort: 'startDate': 1).fetch()

		currentAppointment = _.find today, (a) -> a.startDate < new Date() < a.endDate
		nextAppointmentToday = _.find today, (a) -> new Date() < a.startDate

		foundAppointment = (today.length + tomorrow.length) > 0
		dayOver = not nextAppointmentToday?

		if currentAppointment?
			notices.upsert {
				template: 'infoCurrentAppointment'
			}, {
				template: 'infoCurrentAppointment'
				data: currentAppointment

				header: 'Huidig Lesuur'
				subheader: (
					c = currentAppointment.class()
					c?.name ? currentAppointment.description
				)
				priority: 3

				onClick:
					action: 'route'
					route: 'calendar'
					params:
						time: +Date.today()
			}
		else
			notices.remove template: 'infoCurrentAppointment'

		if nextAppointmentToday?
			notices.upsert {
				template: 'infoNextLesson'
			}, {
				template: 'infoNextLesson'
				data: nextAppointmentToday

				header: 'Volgend Lesuur'
				subheader: (
					c = nextAppointmentToday.class()
					c?.name ? nextAppointmentToday.description
				)
				priority: if Math.abs(_.now() - nextAppointmentToday.startDate) < 300000 then 4 else 2

				onClick:
					action: 'route'
					route: 'calendar'
					params:
						time: +Date.today()
			}
		else
			notices.remove template: 'infoNextLesson'

		###
		$('#currentDate > span').tooltip
			placement: 'bottom'
			html: true
			title: "<h4>Week: #{moment().week()}</h4>"
		###

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

Template.overview.onRendered ->
	###
	@$('#overviewNotices').masonry
		itemSelector: '.notice'
		columnWidth: 200
	###

	slide 'overview'
	setPageOptions
		title: 'Overzicht'
		color: null
