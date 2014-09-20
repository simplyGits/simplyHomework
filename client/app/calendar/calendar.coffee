height = -> $(".content").height() - if Meteor.user().hasPremium then 10 else 100

dblDate = null
dblDateResetHandle = null

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
		titleFormat:
			month: "MMMM YYYY"
			week: "D MMMM YYYY"
			day: "D MMMM YYYY"
		buttonText:
    		today: "deze week"
    		month: "maand"
    		week: "week"
    		day: "dag"
		events: [
			{
				title  : 'weer een saaie dag',
				start  : '2014-09-01'
				editable: no
			},
			{
				title  : 'Saaiheid',
				start  : '2014-09-05T12:30:00',
				end    : '2014-09-05T15:30:00'
				editable: yes
			},
			{
				title  : 'swag',
				start  : '2014-09-04T12:30:00',
				allDay : false
				editable: no
			},
			{
				title: "Events zijn niet altijd overlappend ;)"
				start: "2014-09-05T15:30:00"
				end: "2014-09-05T18:55:00"
				editable: yes
			}
		]
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

	$("button.fc-button").removeClass("fc-button fc-state-default").addClass "btn btn-default"
	$(".fc-right").prepend "<button id=\"newAppointmentButton\" class=\"btn btn-primary\">toevoegen</button>"
	$("button#newAppointmentButton").click open

	$(window).resize -> $('.calendar').fullCalendar('option', 'height', height())

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
	"keydown .calendar": (event) ->
		console.log event.which