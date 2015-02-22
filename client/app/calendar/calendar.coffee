height = -> $(".content").height() - if has("noAds") then 10 else 100
root = @

currentEvents = []

dblDate = null
dblDateResetHandle = null
keydownSet = no

prevDrop = null # Used to only have one event drop open at a time.

appointmentToEvent = (appointment) ->
	type = null
	type = "quiz" if /\b((so)|((luister ?)?toets)|(schriftelijke overhoring))/i.test(appointment.content()?.split(" ")?[0] ? "")
	type = "test" if /\b((proefwerk)|(pw)|(examen)|(tentamen))/i.test(appointment.content()?.split(" ")?[0] ? "")

	id: appointment.id()
	title: (
		if appointment.classes().length > 0
			s = appointment.classes()[0]
			s += " - #{appointment.classRooms()[0]}" if appointment.classRooms()[0]?
		else
			appointment.description()
	)
	allDay: appointment.fullDay()
	start: appointment.begin()
	end: appointment.end()
	color:
		if appointment.scrapped() then "gray"
		else if type is "quiz" then "#FF851B"
		else if type is "test" then "#FF4136"
		else switch appointment.infoType()
			when 1 then "#32A8CE"
			when 2, 3 then "#FF4136"
			when 4, 5 then "#FF851B"

			else "#3a87ad"
	clickable: not appointment.scrapped()
	open: no
	appointment: appointment

calendarItemToEvent = (calendarItem) ->
	type = null
	type = "quiz" if /\b((so)|((luister ?)?toets)|(schriftelijke overhoring))/i.test(calendarItem.description?.split(" ")?[0] ? "")
	type = "test" if /\b((proefwerk)|(pw)|(examen)|(tentamen))/i.test(calendarItem.description?.split(" ")?[0] ? "")

	id: calendarItem._id
	title: (
		if calendarItem.classId? then Classes.findOne(calendarItem.classId).name
		else if calendarItem.description.length > 12 then "#{calendarItem.description.substring(0, 9)}..."
		else calendarItem.description
	)
	allDay: calendarItem.startDate.getHours() is 0 and moment(calendarItem.endDate).diff(calendarItem.startDate, "hours") is 24
	start: calendarItem.startDate
	end: calendarItem.endDate
	color:
		if type is "quiz" then "#FF851B"
		else if type is "test" then "#FF4136"
		else "#3a87ad"
	clickable: yes
	open: no
	calendarItem: calendarItem
	editable: yes

Template.calendar.rendered = ->
	$(".calendar").fullCalendar
		defaultView: "agendaWeek"
		height: height()
		firstDay: 1
		lang: "nl"
		timezone: "local"
		handleWindowResize: no
		allDayText: "hele dag"
		scrollTime: "07:00:00"
		snapDuration: "00:05:00"
		slotDuration: "00:30:00"
		titleFormat:
			month: "MMMM YYYY"
			week: "D MMMM YYYY"
			day: "D MMMM YYYY"
		buttonText:
			today: "deze week"
			month: "maand"
			week: "week"
			day: "dag"
		columnFormat:
			month: "ddd"
			week: "ddd D-M"
			day: "dddd"

		events: (start, end, timezone, callback) ->
			start = start.toDate(); end = end.toDate()
			Session.set "currentDateRange", [start, end]
			callback currentEvents

		dayClick: (date, event, view) ->
			clearTimeout dblDateResetHandle
			date = date.toDate()
			sameYear = date.getUTCFullYear() is new Date().getUTCFullYear()

			if EJSON.equals date, dblDate
				open()
				$("textarea#appointmentInput")
					.val(
						if date.getHours() is 1 and date.getMinutes() is 0
							"#{DateToDutch date, !sameYear} hele dag "
						else
							"#{DateToDutch date, !sameYear} #{Helpers.addZero date.getHours()}:#{Helpers.addZero date.getMinutes()} "
					)

			dblDate = date

			dblDateResetHandle = _.delay ( -> dblDate = dblDateResetHandle = null ), 500

		eventClick: (calendarEvent, event) ->
			prevDrop?.close()
			$(event.target).popover "hide"

			calendarEvent.drop.toggle()
			calendarEvent.open = calendarEvent.drop.isOpened()
			prevDrop = calendarEvent.drop

		eventAfterRender: (event, element) ->
			event.element = element
			if event.appointment?
				element.popover content: event.appointment.content(), placement: "auto top", animation: yes, delay: {show: 750}, trigger: "hover", container: ".content"

			return unless event.clickable

			element.css cursor: "pointer"

			event.drop = new Drop
				target: element
				position: "bottom middle"
				openOn: null # Only open when called done explicity.

			Blaze.renderWithData Template.eventDetailsTooltip, (->
				x = event.appointment
				x ?= event.calendarItem
				return x
			), event.drop.content

		dayRender: (date, cell) ->
			_.defer ->
				return if $(".fc-left h2").text().indexOf("week") isnt -1
				$(".fc-left h2").html "#{$(".fc-left h2").text()} <small>week: #{date.week()}</small>"
		eventDrop: (event) ->
			if event.allDay
				CalendarItems.update event.calendarItem._id, $set: startDate: event.start.toDate().date(), endDate: event.start.toDate().date().addDays 1
			else
				CalendarItems.update event.calendarItem._id, $set: startDate: event.start.toDate(), endDate: event.end?.toDate() ? event.start.add(1, "hour").toDate()
		eventResize: (event) -> CalendarItems.update event.calendarItem._id, $set: startDate: event.start.toDate(), endDate: event.end.toDate()

	$("div.addAppointmentForm").detach().prependTo "body"
	$("button.fc-button").removeClass("fc-button fc-state-default").addClass "btn btn-default"
	$(".fc-right").prepend "<button id=\"newAppointmentButton\" class=\"btn btn-primary\">toevoegen</button>"
	$("button#newAppointmentButton").click open
	Mousetrap.bind "shift+n", (e) -> open(); e.preventDefault()

	$(window).resize -> $('.calendar').fullCalendar('option', 'height', height())

	unless keydownSet
		keydownSet = yes
		$(window).keydown (event) ->
			return if $("input, textarea").is(":focus") or $("body").hasClass "shepherd-active"
			$(".calendar").fullCalendar if event.which is 39 then "next" else if event.which is 37 then "prev"

	@autorun (c) -> # swagger nagger reactivity for FullCalendar.
		currentEvents = []
		[start, end] = Session.get("currentDateRange")

		currentEvents.pushMore updatedAppointments(start, end).map appointmentToEvent
		currentEvents.pushMore CalendarItems.find().map calendarItemToEvent

#		currentEvents.pushMore CalendarItems.find({ $or: [
#			{
#				startDate: $gte: start
#				endDate: $lte: end
#			}
#			{
#				$where: ->
#					targetDate = new Date @startDate.getTime() + @repeatInterval * 1000
#					targetDate = new Date(
#						targetDate.getUTCFullYear(),
#						targetDate.getMonth(),
#						targetDate.getDate()
#					)
#
#					return targetDate >= start and targetDate <= end
#			}
#		] }).map calendarItemToEvent

		### bla bla tasks bla bla ###

		$(".calendar").fullCalendar "refetchEvents"

open = ->
	$("div.addAppointmentForm").addClass "transformIn"
	$("div.backdrop").addClass "dimmed"
	$("div.backdrop, div.addAppointmentForm > .close").click close
	$("div.addAppointmentForm > button#saveButton").click add

	$("textarea#appointmentInput").focus().keydown (event) ->
		close() if event.which is 27
		if event.which is 13 and event.shiftKey
			event.preventDefault()
			add()

close = ->
	$("div.addAppointmentForm").removeClass "transformIn"
	$("div.backdrop").removeClass "dimmed"
	$("textarea#appointmentInput").val("").velocity { height: "54px" }, 500, "easeOutExpo"

add = ->
	input = $("textarea#appointmentInput").val().trim()
	calendarItem = parseCalendarItem input

	if calendarItem?
		CalendarItems.insert calendarItem
		close()
	else shake "div.addAppointmentForm"

Template.calendar.events
	"click button.close": close
