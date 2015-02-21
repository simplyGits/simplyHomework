currentDate = new ReactiveVar Date.today()
cachedAppointments = ReactiveVar {}

appointmentToMobileCalendar = (appointment) -> _.extend appointment,
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
	__classTime: if appointment.fullDay() then "hele dag" else "#{moment(appointment.begin()).format("HH:mm")}-#{moment(appointment.end()).format("HH:mm")}"

calendarItemToMobileCalendar = (calendarItem) -> _.extend calendarItem,
	__colorType: ""
	__classSchoolHour: ""
	__className: if calendarItem.classId? then Classes.findOne(calendarItem.classId).name else ""
	__classLocation: ""
	__classTime: (
		start = calendarItem.startDate
		end = calendarItem.endDate
		isFullDay = start.getHours() is 0 and start.getMinutes() is 0 and (end - start) is 86400000

		if isFullDay then "hele dag"
		else "#{moment(start).format("HH:mm")}-#{moment(end).format("HH:mm")}"
	)

Template.mobileCalendar.helpers
	currentDate: -> "#{DayToDutch(Helpers.weekDay currentDate.get()).substr 0, 2} #{DateToDutch currentDate.get()}"
	today: -> if currentDate.get()? and EJSON.equals currentDate.get().date(), Date.today() then "today" else ""

Template.mobileCalendarPage.helpers
	bottomMargin: -> if has("noAds") then "0px" else "90px"

oldPage = 0
Template.mobileCalendar.rendered = ->
	@autorun -> Meteor.subscribe "calendarItems"

	calendar = new SwipeView ".mobileCalendar"

	for i in [0..2] then do (i) ->
		Blaze.renderWithData Template.mobileCalendarPage, (->
			current = $("#swipeview-slider > div").index calendar.masterPages[i]

			res = []
			res.pushMore magisterAppointment(currentDate.get().addDays current - 1, yes).map appointmentToMobileCalendar
			res.pushMore CalendarItems.find(
				startDate: currentDate.get().date()
				endDate: currentDate.get().date().addDays 1
			)

			return res
		), calendar.masterPages[i]

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
