height = -> $('.content').height() - if has('noAds') then 10 else 100

currentSub = null

dblDate = null
dblDateResetHandle = null
keydownSet = no

calendarItemToEvent = (calendarItem) ->
	type = calendarItem.content?.type
	type = 'quiz' if /^(so|schriftelijke overhoring|(luister\W?)?toets)\b/i.test calendarItem.description
	type = 'test' if /^(proefwerk|pw|examen|tentamen)\b/i.test calendarItem.description

	id: calendarItem._id
	title: (
		if calendarItem.classId? then Classes.findOne(calendarItem.classId).name
		else calendarItem.description
	)
	allDay: calendarItem.fullDay
	start: calendarItem.startDate
	end: calendarItem.endDate
	color: (
		if calendarItem.scrapped then 'gray'
		else switch type
			when 'homework' then '#32A8CE'
			when 'test', 'exam' then '#FF4136'
			when 'quiz', 'oral' then '#FF851B'

			else '#3a87ad'
	)
	clickable: not calendarItem.scrapped
	open: no
	calendarItem: calendarItem
	editable: not calendarItem.fetchedBy?
	content: calendarItem.content

Template.calendar.onRendered ->
	$('.calendar').fullCalendar
		defaultView: 'agendaWeek'
		height: height()
		firstDay: 1
		lang: 'nl'
		timezone: 'local'
		handleWindowResize: no
		allDayText: 'hele dag'
		scrollTime: '07:00:00'
		snapDuration: '00:05:00'
		slotDuration: '00:30:00'
		titleFormat:
			month: 'MMMM YYYY'
			week: 'D MMMM YYYY'
			day: 'D MMMM YYYY'
		buttonText:
			today: 'deze week'
			month: 'maand'
			week: 'week'
			day: 'dag'
		columnFormat:
			month: 'ddd'
			week: 'ddd D-M'
			day: 'dddd'

		events: (start, end, timezone, callback) ->
			[ start, end ] = (d.toDate() for d in [ start, end ])

			currentSub?.stop()
			currentSub = Meteor.subscribe 'externalCalendarItems', start, end, ->
				callback CalendarItems.find(
					startDate: $gte: start
					endDate: $lte: end
				).map calendarItemToEvent

		dayClick: (date, event, view) ->
			clearTimeout dblDateResetHandle
			date = date.toDate()
			sameYear = date.getUTCFullYear() is new Date().getUTCFullYear()

			if EJSON.equals date, dblDate
				open()
				$('textarea#appointmentInput')
					.val(
						if date.getHours() is 1 and date.getMinutes() is 0
							"#{DateToDutch date, not sameYear} hele dag "
						else
							"#{DateToDutch date, not sameYear} #{Helpers.addZero date.getHours()}:#{Helpers.addZero date.getMinutes()} "
					)

			dblDate = date

			dblDateResetHandle = _.delay ( -> dblDate = dblDateResetHandle = null ), 500

		eventClick: (calendarEvent, event) ->
			$(event.target).popover "hide"

		eventAfterRender: (event, element) ->
			event.element = element
			if event.content?
				element.popover
					content: event.content.description
					placement: 'auto top'
					animation: yes
					delay: { show: 750 }
					trigger: 'hover'
					container: '.content'

			return unless event.clickable

			element.css cursor: "pointer"

		dayRender: (date, cell) ->
			Meteor.defer ->
				header = $ ".fc-left h2"
				return if header.text().indexOf("week") isnt -1
				header.html "#{$(".fc-left h2").text()} <small>week: #{date.week()}</small>"

		eventDrop: (event) ->
			CalendarItems.update event.calendarItem._id, $set:
				startDate: event.start.toDate()
				endDate: event.end?.toDate() ? event.start.add(1, "hour").toDate()

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
