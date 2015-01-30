height = -> $(".content").height() - if has("noAds") then 10 else 100
root = @

dblDate = null
dblDateResetHandle = null
keydownSet = no

getHardCacheAppointments = (begin, end) ->
	x = _.filter (Appointment._convertStored root.magister, a for a in hardCachedAppointments), (x) -> x.begin() >= begin and x.end() <= end
	return _.reject x, (a) -> a.id() isnt -1 and _.any(x, (z) -> z isnt a and z.begin() is a.begin() and z.end() is a.end() and z.description() is a.description())

setHardCacheAppointments = (data) ->
	for appointment in data
		_.remove hardCachedAppointments, (x) ->
			x = Appointment._convertStored(root.magister, x)
			return "#{x.begin().getTime()}#{x.end().getTime()}" is "#{appointment.begin().getTime()}#{appointment.end().getTime()}"

		hardCachedAppointments.push appointment._makeStorable()

	_.remove hardCachedAppointments, (x) -> x.end() < new Date().addDays(-7) or x.begin() > new Date().addDays(14)
	amplify.store "hardCachedAppointments_#{Meteor.userId()}", JSON.decycle(hardCachedAppointments), expires: 432000000

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
	allDay: calendarItem.startDate.getHours() is 0 and moment(calendarItem.endDate).diff(calendarItem.beginDate, "hours") is 24
	start: calendarItem.startDate
	end: calendarItem.endDate
	color:
		if type is "quiz" then "#FF851B"
		else if type is "test" then "#FF4136"
		else "#3a87ad"
	clickable: yes
	open: no
	calendarItem: calendarItem

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
			calendarItems = CalendarItems.find({}, transform: calendarItemToEvent).fetch()

			allCached = magisterAppointment start, end, no, yes, (error, result, fromCache) ->
				unless fromCache
					$(".calendar").fullCalendar "refetchEvents" # Needed to get a new callback since we already used the current one for the hard cached appointments.
					return

				result.map (appointment) ->
					return appointment unless appointment.scrapped()
					a = _.find getHardCacheAppointments(start, end), (a) -> "#{appointment.begin().getTime()}#{appointment.end().getTime()}" is "#{a.begin().getTime()}#{a.end().getTime()}"
					if a?
						appointment._description = a._description
						appointment._location = a._location
						appointment._begin = a._begin
						appointment._end = a._end
					return appointment

				events = (appointmentToEvent x for x in result)

				callback events.concat calendarItems

			unless allCached
				callback (appointmentToEvent x for x in getHardCacheAppointments(start, end)).concat calendarItems

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
			else
				calendarEvent.open = no
		loading: (isLoading) -> if isLoading then NProgress.start() else NProgress.done()
		eventAfterRender: (event, element) ->
			event.element = element
			if event.appointment?
				element.popover content: event.appointment.content(), placement: "auto top", animation: yes, delay: {show: 750}, trigger: "hover", container: ".content"
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
		dayRender: (date, cell) ->
			_.defer ->
				return if $(".fc-left h2").text().indexOf("week") isnt -1
				$(".fc-left h2").html "#{$(".fc-left h2").text()} <small>week: #{date.week()}</small>"

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

	@autorun (c) -> # Keep the current view updated.
		if Meteor.status().connected and not c.firstRun
			updatedAppointments Session.get("currentDateRange")...
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

infos = [
	[/volgende (\w+) les/i, 1, "lesson", 1]
	[/volgende les (\w+)/i, 1, "lesson", 1]
	[/(\w+) volgende les/i, 1, "lesson", 1]

	[/vorige (\w+) les/i, -1, "lesson", 1]
	[/vorige les (\w+)/i, -1, "lesson", 1]
	[/(\w+) vorige les/i, -1, "lesson", 1]

	[/(\w+) eergister(en)?/i, "eergister", "lesson", 1]
	[/(\w+) gister(en)?/i, "gister", "lesson", 1]
	[/(\w+) morgen/i, "morgen", "lesson", 1]
	[/(\w+) overmorgen/i, "overmorgen", "lesson", 1]

	[/eergister(en)?/i, -2, "days"]
	[/gister(en)?/i, -1, "days"]
	[/vandaag/i, 0, "days"]
	[/morgen/i, 1, "days"]
	[/overmorgen/i, 2, "days"]

	[/(\w+) maandag/i, "maandag", "lesson", 1]
	[/(\w+) dinsdag/i, "dinsdag", "lesson", 1]
	[/(\w+) woensdag/i, "woensdag", "lesson", 1]
	[/(\w+) donderdag/i, "donderdag", "lesson", 1]
	[/(\w+) vrijdag/i, "vrijdag", "lesson", 1]
	[/(\w+) zaterdag/i, "zaterdag", "lesson", 1]
	[/(\w+) zondag/i, "zondag", "lesson", 1]
	[/maandag (\w+)/i, "maandag", "lesson", 1]
	[/dinsdag (\w+)/i, "dinsdag", "lesson", 1]
	[/woensdag (\w+)/i, "woensdag", "lesson", 1]
	[/donderdag (\w+)/i, "donderdag", "lesson", 1]
	[/vrijdag (\w+)/i, "vrijdag", "lesson", 1]
	[/zaterdag (\w+)/i, "zaterdag", "lesson", 1]
	[/zondag (\w+)/i, "zondag", "lesson", 1]

	[/((volgende|aankomende) )?maandag/i, "maandag", null]
	[/((volgende|aankomende) )?dinsdag/i, "dinsdag", null]
	[/((volgende|aankomende) )?woensdag/i, "woensdag", null]
	[/((volgende|aankomende) )?donderdag/i, "donderdag", null]
	[/((volgende|aankomende) )?vrijdag/i, "vrijdag", null]
	[/((volgende|aankomende) )?zaterdag/i, "zaterdag", null]
	[/((volgende|aankomende) )?zondag/i, "zondag", null]

	[/(vorige|afgelopen) maandag/i, "-maandag", null]
	[/(vorige|afgelopen) dinsdag/i, "-dinsdag", null]
	[/(vorige|afgelopen) woensdag/i, "-woensdag", null]
	[/(vorige|afgelopen) donderdag/i, "-donderdag", null]
	[/(vorige|afgelopen) vrijdag/i, "-vrijdag", null]
	[/(vorige|afgelopen) zaterdag/i, "-zaterdag", null]
	[/(vorige|afgelopen) zondag/i, "-zondag", null]

	[/(volgende|aankomende) week/i, 1, "weeks"]
	[/(vorige|afgelopen) week/i, -1, "weeks"]
	[/(over|na) (\d+) (weken|week)/i, null, "weeks", 2]
	[/(\d+) (weken|week) geleden/i, null, "weeks", 1]

	[/(over|na) (\d+) (dagen|dag)/i, null, "days", 2]
	[/(\d+) (dagen|dag) geleden/i, null, "days", 1]
]

add = ->
	input = $("textarea#appointmentInput").val().trim()
	date = null
	endDate = null
	appointment = null
	descriptionOnly = null
	doBreak = no
	for info, i in infos
		[reg, target, type, targetGroup] = info
		targetGroup ?= 0

		if (val = reg.exec(input)?[0])?
			descriptionOnly = input.replace val, ""
			if targetGroup isnt 0 then val = reg.exec(val)[targetGroup]

			date = switch type
				when "days" then new Date().addDays (target ? +val)
				when null and target[0] isnt "-"
					x = moment()
					x.add 1, "days" while dutchDays[x.weekday()] isnt target
					x.toDate()
				when null and target[0] is "-"
					x = moment()
					x.add -1, "days" while dutchDays[x.weekday()] isnt target[1..]
					x.toDate()
				when "weeks" then new Date().addDays (target ? +val) * 7
				when "lesson"
					calcDistance = _.curry (s) -> DamerauLevenshtein(transpose: .5)(val.trim().toLowerCase(), s.trim().toLowerCase())
					z = _.filter magisterResult("appointments this week").result, (c) -> c.classes().length > 0
					distances = []

					for appointment in _.uniq(z, (c) -> c.classes()[0])
						name = appointment.classes()[0]
						if name.length > 4 and val.length > 4 and (( val.toLowerCase().indexOf(name.toLowerCase()) > -1 ) or ( name.toLowerCase().indexOf(val.toLowerCase()) > -1 ))
							distances.push { name, distance: 0 }
						else if (distance = calcDistance name) < 2
							distances.push { name, distance }

					if distances.length is 0 then break
					{ name, distance } = _.sortBy(distances, "distance")[0]

					if target is 1
						appointment = _.find(z, (c) -> c.classes()[0] is name and c.begin().date() > Date.today())
						date = appointment?.begin()
						endDate = appointment?.end()
					else if target is -1
						appointment = _.find(z, (c) -> c.classes()[0] is name and c.end().date() < Date.today())
						date = appointment?.begin()
						endDate = appointment?.end()

					else if target is "morgen"
						appointment = _.find(z, (c) -> c.classes()[0] is name and EJSON.equals c.begin().date(), Date.today().addDays(1))
						date = appointment?.begin()
						endDate = appointment?.end()
						doBreak = yes
					else if target is "overmorgen"
						appointment = _.find(z, (c) -> c.classes()[0] is name and EJSON.equals c.begin().date(), Date.today().addDays(2))
						date = appointment?.begin()
						endDate = appointment?.end()
						doBreak = yes
					else if target is "gister"
						appointment = _.find(z, (c) -> c.classes()[0] is name and EJSON.equals c.begin().date(), Date.today().addDays(-1))
						date = appointment?.begin()
						endDate = appointment?.end()
						doBreak = yes
					else if target is "eergister"
						appointment = _.find(z, (c) -> c.classes()[0] is name and EJSON.equals c.begin().date(), Date.today().addDays(-2))
						date = appointment?.begin()
						endDate = appointment?.end()
						doBreak = yes

					else
						appointment = _.find(z, (c) -> c.classes()[0] is name and c.begin().date() >= Date.today() and dutchDays[moment(c.begin().date()).weekday()] is target)
						date = appointment?.begin()
						endDate = appointment?.end()
						doBreak = yes

					date

		break if date? or doBreak

	unless date?
		match = /(\d{0,3} (\w+|\d+) (\d{4})?)|((\d{4})? (\w+\d+) \d{0,3})/.exec(input)?[0]
		descriptionOnly = input.replace match, ""
		date = new Date val unless _.isNaN val = Date.parse match

	unless date? or doBreak
		calcDistance = _.curry (s) -> DamerauLevenshtein(transpose: .5)(word.trim().toLowerCase(), s.trim().toLowerCase())
		z = _.filter magisterResult("appointments this week").result, (c) -> c.classes().length > 0
		for word in input.split " "
			distances = []

			for appointment in _.uniq(z, (c) -> c.classes()[0])
				name = appointment.classes()[0]
				if name.length > 4 and word.length > 4 and (( word.toLowerCase().indexOf(name.toLowerCase()) > -1 ) or ( name.toLowerCase().indexOf(word.toLowerCase()) > -1 ))
					distances.push { name, distance: 0 }
				else if (distance = calcDistance name) < 2
					distances.push { name, distance }

			if distances.length is 0 then break
			{ name, distance } = _.sortBy(distances, "distance")[0]

			appointment = _.find(z, (c) -> c.classes()[0] is name and c.begin().date() > Date.today())
			date = appointment?.begin()
			endDate = appointment?.end()
			if date?
				descriptionOnly = (descriptionOnly ? "").replace word, ""
				break

	unless endDate? or doBreak
		match = /\S+ ?(-|tot) ?(\S+)/i.exec(input)?[2]
		if match?
			descriptionOnly = (descriptionOnly ? "").replace match, ""

			val = Date.parse(match)
			endDate = new Date(val) unless _.isNaN val

	if date?
		close()

		classId = null
		if appointment? and not _.isEmpty appointment.description()
			classId = _.find(Meteor.user().profile.groupInfos, (gi) -> gi.group is appointment.description())?.id

		New.calendarItem Meteor.userId(), (if descriptionOnly? then descriptionOnly else input).trim(), date, endDate, classId
	else
		$("div.addAppointmentForm").addClass "animated shake"
		$("div.addAppointmentForm").one 'webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', ->
			$("div.addAppointmentForm").removeClass "animated shake"

Template.calendar.events
	"click button.close": close
