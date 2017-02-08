Tether = require 'tether'

POPOVER_RESET_TIME_MS = 150

currentSub = undefined

dblDate = undefined
dblDateResetHandle = undefined

currentOpenEvent = new ReactiveVar
popoverTimeout = undefined
popoverView = undefined
lastHoverStop = -1

height = ->
	$('.content').height()

setQueryParam = (id) ->
	FlowRouter.withReplaceState ->
		FlowRouter.setQueryParams openCalendarItemId: id

openCalendarItemsModal = (id) ->
	return unless id?

	Meteor.defer ->
		setQueryParam id
		showModal 'calendarItemDetailsModal', {
			onHide: -> setQueryParam undefined
		}, -> CalendarItems.findOne id

calendarItemToEvent = (calendarItem, comparing = no) ->
	_class = Classes.findOne calendarItem.classId

	id: calendarItem._id
	title: _class?.name ? calendarItem.description
	allDay: calendarItem.fullDay
	start: calendarItem.startDate
	end: calendarItem.endDate
	color: (
		if comparing is 'other'
			if calendarItem.scrapped then '#458A83'
			else '#009688'
		else if calendarItem.scrapped then 'gray'
		else switch calendarItem.content?.type
			when 'homework' then '#32A8CE'
			when 'test', 'exam' then '#FF4136'
			when 'quiz', 'oral' then '#FF851B'

			else '#3a87ad'
	)
	className: (
		classes = []

		type = calendarItem.getAbsenceInfo()?.type
		if not comparing and type in [ 'absent', 'sick', 'exemption', 'discharged' ]
			classes.push 'opaque'

		if comparing isnt no and not calendarItem.fullDay
			classes.push comparing

		classes.join ' '
	) ? ''
	comparing: comparing is 'other'
	calendarItem: calendarItem
	# kinda HACK
	# TODO: Update edited calendarItems to upstream.
	editable: _.every calendarItem.externalInfos, 'editable'
	content: calendarItem.content

Template.calendar.onCreated ->
	@subscribe 'classes', hidden: yes

Template.calendar.onRendered ->
	unless $::fullCalendar?
		document.location.reload()

	slide 'calendar'
	setPageOptions
		title: 'Agenda'
		color: null

	dates = new ReactiveVar []
	currentItems = []
	$calendar = @$ '.calendar'
	$calendar.fullCalendar
		# TODO: this has to be removed when we have custom calendarItems back
		# working.
		weekends: false

		defaultView: 'agendaWeek'
		height: height()
		firstDay: 1
		nowIndicator: yes
		lang: 'nl'
		timezone: 'local'
		handleWindowResize: no
		allDayText: 'hele dag'
		scrollTime: '07:00:00'
		snapDuration: '00:05:00'
		weekNumbers: yes
		weekNumberTitle: 'week '
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

		eventOrder: [ 'comparing', 'title' ]

		events: (start, end, timezone, callback) ->
			callback currentItems

		dayClick: (date, event, view) ->
			clearTimeout dblDateResetHandle
			date = date.toDate()

			if EJSON.equals date, dblDate
				open()
				$('textarea#appointmentInput').val (
					sameYear = date.getFullYear() is new Date().getFullYear()
					dateStr = DateToDutch date, not sameYear

					if date.getHours() is 1 and date.getMinutes() is 0
						"#{dateStr} hele dag "
					else
						"#{dateStr} #{Helpers.addZero date.getHours()}:#{Helpers.addZero date.getMinutes()} "
				)

			dblDate = date
			dblDateResetHandle = _.delay (->
				dblDate = dblDateResetHandle = null
			), 500

		eventMouseover: (calendarEvent, event) ->
			Meteor.clearTimeout popoverTimeout
			fn = ->
				ga 'send', 'event', 'calendarEventPopover', 'open'
				currentOpenEvent.set calendarEvent
				Meteor.defer ->
					new Tether
						element: document.getElementById 'eventDetailsTooltip'
						target: event.currentTarget
						attachment: 'top left'
						targetAttachment: 'top right'
						constraints: [
							{
								to: 'scrollParent',
								attachment: 'together'
								pin: yes
							}
						]
			popoverTimeout = Meteor.setTimeout fn, (
				if _.now() - lastHoverStop < POPOVER_RESET_TIME_MS then 0
				else 500
			)

		eventMouseout: (calendarEvent, event) ->
			Meteor.clearInterval popoverTimeout
			if currentOpenEvent.get()?
				currentOpenEvent.set undefined
				lastHoverStop = _.now()

		eventClick: (calendarEvent, event) ->
			ga 'send', 'event', 'calendarItemsModal', 'open'
			Meteor.clearInterval popoverTimeout
			currentOpenEvent.set undefined
			openCalendarItemsModal calendarEvent.calendarItem._id

		viewRender: (view, element) ->
			dates.set (d.toDate().date() for d in [ view.start, view.end ])

			Meteor.defer ->
				FlowRouter.withReplaceState ->
					FlowRouter.setParams time: +view.start

		# REVIEW: handle updating with methods?
		eventDrop: (event) ->
			CalendarItems.update event.calendarItem._id, $set:
				startDate: event.start.toDate()
				endDate: event.end?.toDate() ? event.start.add(1, "hour").toDate()

		eventResize: (event) ->
			CalendarItems.update event.calendarItem._id, $set:
				startDate: event.start.toDate()
				endDate: event.end.toDate()

		eventAfterAllRender: ->
			Blaze.remove popoverView if popoverView?
			popoverView = Blaze.renderWithData Template.eventDetailsTooltip, (->
				currentOpenEvent.get()?.calendarItem
			), document.body

	time = +FlowRouter.getParam 'time'
	if isFinite time
		$calendar.fullCalendar 'gotoDate', time
	else if getUserField(
		Meteor.userId()
		'settings.devSettings.desktopCalendarWeekendSkip'
		no
	) and new Date().getDay() in [ 6, 0 ]
		$calendar.fullCalendar 'gotoDate', new Date().addDays 3
	openCalendarItemsModal FlowRouter.getQueryParam 'openCalendarItemId'

	@$('.addAppointmentForm').detach().prependTo "body"
	$calendar
		.find 'button.fc-button'
		.removeClass 'fc-button fc-state-default'
		.addClass 'btn btn-default'
	# TODO: fix adding calendarItems n stuff. When fixed uncomment next 2 lines.
	##$calendar.find('.fc-right').prepend '<button id="newAppointmentButton" class="btn btn-primary">toevoegen</button>'
	##$calendar.find('button#newAppointmentButton').click open
	Mousetrap.bind 'shift+n', (e) ->
		open()
		false

	# Handle Resizing
	resize = -> $calendar.fullCalendar('option', 'height', height())
	@autorun (c) ->
		currentBigNotice._reactiveVar.dep.depend()
		resize() unless c.firstRun
	$(window).resize resize

	@autorun =>
		dateTracker.depend()

		ids = FlowRouter.getQueryParam 'userIds'
		comparing = ids? and ids.length > 0

		[ start, end ] = dates.get()
		@subscribe 'externalCalendarItems', start, end
		currentItems = CalendarItems.find({
			userIds: Meteor.userId()
			startDate: $gte: start
			endDate: $lte: end
		}, {
			sort: startDate: 1
		}).map (item) -> calendarItemToEvent item, if comparing then 'own' else no

		if comparing
			@subscribe 'foreignCalendarItems', ids, start, end
			currentItems = currentItems.concat CalendarItems.find({
				userIds: $in: ids
				startDate: $gte: start
				endDate: $lte: end
				type: $ne: 'schoolwide'
			}, {
				sort: startDate: 1
			}).map (item) -> calendarItemToEvent item, 'other'

		$calendar.fullCalendar 'refetchEvents'

	Mousetrap.bind 'left', ->
		$calendar.fullCalendar 'prev'
		false

	Mousetrap.bind 'right', ->
		$calendar.fullCalendar 'next'
		false

	Mousetrap.bind 'space', ->
		$calendar.fullCalendar 'today'
		false

	Mousetrap.bind 'esc', ->
		$('#calendarItemDetailsModal').modal 'hide'
		false

Template.calendar.onDestroyed ->
	Mousetrap.unbind [ 'left', 'right', 'space', 'esc', 'shift+n' ]
	# Force reset the eventDetailsTooltip, since it's possible that we switched
	# route without triggering the mouseout event on fullcalendar (switching by
	# using keyboard shortcuts for example).
	Meteor.clearTimeout popoverTimeout
	Blaze.remove popoverView if popoverView?
	currentOpenEvent.set null
	currentSub?.stop()

open = ->
	# TODO: fix adding calendarItems n stuff. When fixed uncomment next line.
	return

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
	$("textarea#appointmentInput").val("").animate { height: "54px" }, 500, "easeOutExpo"

add = ->
	input = $("textarea#appointmentInput").val().trim()
	calendarItem = parseCalendarItem input

	if calendarItem?
		CalendarItems.insert calendarItem
		close()
	else shake "div.addAppointmentForm"

Template.calendar.events
	"click button.close": close
