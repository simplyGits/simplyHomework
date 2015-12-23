Template.overview.helpers
	currentDate: DateToDutch
	currentDay: DayToDutch
	weekNumber: -> moment().week()

	itemContainerMargin: ->
		margin = 260
		margin -= 170 unless hasAppointments()
		"#{margin}px"

	projects: -> projects()

@originals = {}

Template.overview.events
	'click #addProjectIcon': -> showModal 'addProjectModal'

Template.infoNextDay.helpers
	firstHour: -> _.first(appointmentsTommorow.get()).schoolHour
	lastHour: -> _.last(appointmentsTommorow.get()).schoolHour

Template.overview.onCreated ->
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
