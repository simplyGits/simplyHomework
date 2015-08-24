currentDate = new ReactiveVar Date.today()

calendarItemToMobileCalendar = (calendarItem) -> _.extend calendarItem,
	__colorType: (
		if calendarItem.scrapped then 'scrapped'
		else switch calendarItem.content?.type
			when 'homework' then 'homework'
			when 'test', 'exam' then 'test'
			when 'quiz', 'oral' then 'quiz'

			else ''
	)
	__classSchoolHour: calendarItem.schoolHour ? ''
	__className: calendarItem.description ? Classes.findOne(calendarItem.classId)?.name ? ''
	__classLocation: calendarItem.location ? ''
	__classTime: (
		if calendarItem.fullDay
			'hele dag'
		else
			start = calendarItem.startDate
			end = calendarItem.endDate

			"#{moment(start).format("HH:mm")}-#{moment(end).format("HH:mm")}"
	)

Template.mobileCalendar.helpers
	currentDate: -> "#{DayToDutch(Helpers.weekDay currentDate.get()).substr 0, 2} #{DateToDutch currentDate.get()}"
	today: -> if currentDate.get()? and EJSON.equals currentDate.get().date(), Date.today() then "today" else ""

Template.mobileCalendarPage.helpers
	bottomMargin: -> if has("noAds") then "0px" else "90px"

oldPage = 0
Template.mobileCalendar.rendered = ->
	@subscribe 'externalCalendarItems', currentDate.get(), currentDate.get()

	calendar = new SwipeView ".mobileCalendar"

	for i in [0..2] then do (i) ->
		Blaze.renderWithData Template.mobileCalendarPage, (->
			current = $("#swipeview-slider > div").index calendar.masterPages[i]

			CalendarItems.find {
				startDate: $lte: currentDate.get().date()
				endDate: $gt: currentDate.get().date()
			}, transform: calendarItemToMobileCalendar
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
