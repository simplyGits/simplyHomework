height = -> $(".content").height() - if has("noAds") then 10 else 100
root = @

dblDate = null
dblDateResetHandle = null
keydownSet = no

calendarSprings = {}
springSystem = new rebound.SpringSystem()

bounceEventInfo = (val, id) -> $("div.eventInfo##{id}").css transform: "scale(#{val})"

bounce = (open, id) ->
	$("div.eventInfo##{id}").velocity({ opacity: 1 }, 150)
	calendarSpring(id).setCurrentValue(if open then 1 else 0).setAtRest()

calendarSpring = (id) ->
	unless _.contains _.keys(calendarSprings), id
		calendarSprings[id] = new springSystem.createSpring 40, 6
		calendarSprings[id].addListener
			onSpringUpdate: (spring) ->
				val = spring.getCurrentValue()
				val = rebound.MathUtil.mapValueInRange val, 0, 1, 1, -20
				bounceEventInfo val, id
	return calendarSprings[id]

cachedAppointments = {}

Deps.autorun => if Meteor.user()? then @hardCachedAppointments = amplify.store("hardCachedAppointments_#{Meteor.userId()}") ? []

getHardCacheAppointments = (begin, end) ->
	x = _.filter (Appointment._convertStored root.magister, a for a in hardCachedAppointments), (x) -> x.begin() >= begin and x.end() <= end
	return _.reject x, (a) -> a.id() isnt -1 and _.any(x, (z) -> z.begin() is a.begin() and z.end() is a.end() and z.description() is a.description())

setHardCacheAppointments = (data) ->
	for appointment in data
		_.remove hardCachedAppointments, (x) ->
			x = Appointment._convertStored(root.magister, x)
			return "#{x.begin().getTime()}#{x.end().getTime()}" is "#{appointment.begin().getTime()}#{appointment.end().getTime()}"

		hardCachedAppointments.push appointment._makeStorable()

	_.remove hardCachedAppointments, (x) -> x.end() < new Date().addDays(-7) or x.begin() > new Date().addDays(14)
	amplify.store "hardCachedAppointments_#{Meteor.userId()}", JSON.decycle(hardCachedAppointments), expires: 432000000

Meteor.setInterval ( ->
	if Meteor.status().connected
		cachedAppointments[Session.get("currentDateRange")] = undefined
		$(".calendar").fullCalendar "refetchEvents"
), 1800000

toEvent = (appointment) ->
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
		else switch appointment.infoType()
			when 1 then "#32A8CE"
			when 2, 3 then "#FF4136"
			when 4, 5 then "#FF851B"
			
			else "#3a87ad"
	clickable: not appointment.scrapped()
	open: no
	appointment: appointment

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

			Session.set "currentDateRange", "#{start.getTime()}#{end.getTime()}"

			if (val = cachedAppointments["#{start.getTime()}#{end.getTime()}"])?
				callback val
			else
				unless (val = getHardCacheAppointments(start, end)).length is 0
					callback (toEvent x for x in val)
					updateNeeded = yes

				root.magister.ready ->
					root.magister.appointments start, end, no, (error, result) ->
						setHardCacheAppointments result
						result.map (appointment) ->
							return appointment unless appointment.scrapped()
							a = _.find getHardCacheAppointments(start, end), (a) -> "#{appointment.begin().getTime()}#{appointment.end().getTime()}" is "#{a.begin().getTime()}#{a.end().getTime()}"
							if a?
								a._scrapped is yes
								return a
							return appointment
						result.pushMore _.reject getHardCacheAppointments(start, end), (a) -> _.any result, (x) -> "#{x.begin().getTime()}#{x.end().getTime()}" is "#{a.begin().getTime()}#{a.end().getTime()}"
						
						events = (toEvent x for x in result)

						cachedAppointments["#{start.getTime()}#{end.getTime()}"] = events
						if updateNeeded then $(".calendar").fullCalendar "refetchEvents"
						else callback events
		dayClick: (date, event, view) ->
			clearTimeout dblDateResetHandle
			date = date.toDate()
			sameYear = date.getUTCFullYear() is new Date().getUTCFullYear()

			if EJSON.equals date, dblDate
				open()
				$("textarea#appointmentInput")
					.val(
						if date.getHours() is 2 and date.getMinutes() is 0
							"#{DateToDutch date, !sameYear} hele dag "
						else
							"#{DateToDutch date, !sameYear} #{Helpers.addZero date.getHours()}:#{Helpers.addZero date.getMinutes()} "
					)

			dblDate = date

			dblDateResetHandle = _.delay ( -> dblDate = dblDateResetHandle = null ), 500
		eventClick: (calendarEvent, event) ->
			unless calendarEvent.open
				calendarEvent.open = yes
				calendarSpring(calendarEvent.id)
			else
				calendarEvent.open = no
		loading: (isLoading) -> if isLoading then NProgress.start() else NProgress.done()
		eventAfterRender: (event, element) ->
			event.element = element
			element.popover content: event.appointment.content(), placement: "auto top", animation: yes, delay: {show: 750}, trigger: "hover"
			return unless event.clickable
			
			element = $(element)
			element.css cursor: "pointer"
			return #sometime
		
			d = $ document.createElement "div"
			d.addClass "eventInfo"
			d.attr "id", event.id
			
			left = element.offset().left - 150 - element.width()
			top = element.offset().top - 100 - element.height()

			console.log "#{left} | #{element.position().left} | width of D: 150 | Target: 272"
			console.log "#{top} | #{element.position().top} | height of D: 100 | Target: 406"

			d.css top: "#{top}px", left: "#{left}px"

			element.parent(".fc-event-container").append d

	$("button.fc-button").removeClass("fc-button fc-state-default").addClass "btn btn-default"
	$(".fc-right").prepend "<button id=\"newAppointmentButton\" class=\"btn btn-primary\">toevoegen</button>"
	$("button#newAppointmentButton").click open

	$(window).resize -> $('.calendar').fullCalendar('option', 'height', height())

	unless keydownSet
		keydownSet = yes
		$(window).keydown (event) ->
			return if $("input, textarea").is(":focus")
			$(".calendar").fullCalendar if event.which is 39 then "next" else if event.which is 37 then "prev"

open = ->
	$("div.addAppointmentForm").addClass "transformIn"
	$("div.backdrop").addClass "dimmed"
	$("div.backdrop").click close

	$("textarea#appointmentInput").focus().keydown (event) -> close() if event.which is 27

close = ->
	$("div.addAppointmentForm").removeClass "transformIn"
	$("div.backdrop").removeClass "dimmed"
	$("textarea#appointmentInput").val("").velocity { height: "54px" }, 500, "easeOutExpo"

add = ->
	# ...
	close()

Template.calendar.events
	"click button.close": close