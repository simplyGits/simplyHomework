currentDate = new ReactiveVar Date.today()
cachedAppointments = ReactiveVar {}

fetch = (start, end) =>
	@magisterAppointment start, end, no, (error, result) ->
		x = cachedAppointments.get()
		dates = _(result).uniq((a) -> a.begin().date()).map((a) -> a.begin().date()).value()
		for date in dates
			appointments = _.filter result, (a) -> EJSON.equals a.begin().date(), date

			x["#{date.getTime()}"] = _.map appointments, ((appointment) -> _.extend appointment,
				__colorType: (
					if appointment.scrapped() then "scrapped"
					else switch appointment.infoType()
						when 1 then "homework"
						when 2, 3 then "quiz"
						when 4, 5 then "test"

						else ""
				)

				__classSchoolHour: appointment.beginBySchoolHour() ? ""
				__className: (
					if not appointment.classes()[0]?
						appointment.description()
					else if (val = Helpers.cap appointment.classes()[0]).length <= 24
						val
					else
						appointment.description().split("-")[0].trim()
				)
				__classLocation: appointment.location() ? ""
				__classTime: "#{moment(appointment.begin()).format("HH:mm")}-#{moment(appointment.end()).format("HH:mm")}"
			)
		cachedAppointments.set x

Template.mobileCalendar.helpers
	currentDate: -> DateToDutch currentDate.get()
	today: -> if currentDate.get()? and EJSON.equals currentDate.get().date(), Date.today() then "today" else ""

Template.mobileCalendarPage.helpers
	bottomMargin: -> if has("noAds") then "0px" else "90px"

oldPage = 0
Template.mobileCalendar.rendered = =>
	@calendar = new SwipeView ".mobileCalendar"

	for i in [0..2] then do (i) ->
		Blaze.renderWithData Template.mobileCalendarPage, (->
			current = $("#swipeview-slider > div").index calendar.masterPages[i]

			cachedAppointments.get()["#{currentDate.get().addDays(current - 1, yes).getTime()}"]
		), calendar.masterPages[i]

	fetch currentDate.get().addDays(-1, yes), currentDate.get().addDays(1, yes)

	calendar.onFlip ->
		return if oldPage is calendar.pageIndex
		delta = switch oldPage
			when 0
				if calendar.pageIndex is 2 then -1
				else 1
			when 1
				if calendar.pageIndex is 0 then -1
				else 1
			when 2
				if calendar.pageIndex is 0 then 1
				else -1

		if delta is 1
			$("#swipeview-slider > div:first-child").detach().appendTo "#swipeview-slider"
		else
			$("#swipeview-slider > div:last-child").detach().prependTo "#swipeview-slider"

		oldPage = calendar.pageIndex
		currentDate.set currentDate.get().addDays delta, yes

		fetch currentDate.get().addDays(-1, yes), currentDate.get().addDays(1, yes)
