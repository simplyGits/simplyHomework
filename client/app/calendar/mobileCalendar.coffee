calendarSubs = new SubsManager
	cacheLimit: 4 # this means we can stay subscribed to 6 dates at max
	expireIn: 720 # 12 hours

currentDate = ->
	time = +FlowRouter.getParam 'time'
	if isFinite(time) then new Date(time).date() else Date.today()

setDate = (date) ->
	FlowRouter.withReplaceState ->
		FlowRouter.setParams time: date.getTime()

setDateDelta = (delta) ->
	setDate currentDate().addDays(delta)

getUserIds = -> FlowRouter.getQueryParam 'userIds'

calendarItemToMobileCalendar = (calendarItem) ->
	calendarItem = _.extend new CalendarItem, calendarItem
	_.extend calendarItem,
		__type: (
			if calendarItem.scrapped then 'scrapped'
			else switch calendarItem.content?.type
				when 'homework' then 'homework'
				when 'test', 'exam' then 'test'
				when 'quiz', 'oral' then 'quiz'

				else ''
		)
		__absent: (
			switch calendarItem.getAbsenceInfo()?.type
				when 'absent', 'sick', 'exemption', 'discharged' then 'absent'
				else ''
		)
		__classSchoolHour: calendarItem.schoolHour ? ''
		__className: Classes.findOne(calendarItem.classId)?.name ? calendarItem.description ? ''
		__classLocation: calendarItem.location ? ''
		__classTime: (
			if calendarItem.fullDay
				'hele dag'
			else
				start = moment calendarItem.startDate
				end = moment calendarItem.endDate
				format = 'HH:mm'

				"#{start.format format} - #{end.format format}"
		)

Template.mobileCalendar.helpers
	openCalendarItem: ->
		CalendarItems.findOne FlowRouter.getQueryParam 'openCalendarItemId'
	currentDate: ->
		date = currentDate()
		"#{DayToDutch(Helpers.weekDay date).substr 0, 2} #{DateToDutch date}"
	today: ->
		dateTracker.depend()
		date = currentDate()
		if date? and moment(date).isSame(new Date, 'day')
			'today'
		else
			''
	comparing: -> if getUserIds()?.length > 0 then 'comparing' else ''

Template.mobileCalendar.events
	'click .currentDate': -> setDate Date.today()
	'click [data-action="pickdate"]': -> $('#datepickercontainer').addClass 'visible'
	'click #backdrop': -> $('#datepickercontainer').removeClass 'visible'

Template.mobileCalendarHour.events
	'click .hour': -> FlowRouter.setQueryParams openCalendarItemId: @_id

Template.mobileCalendarItemDetails.events
	'click #closeButton': -> history.back()

Template.mobileCalendarHour.helpers
	current: ->
		minuteTracker.depend()
		if @startDate <= new Date() <= @endDate and not @scrapped and not @fullDay
			'current'
		else
			''

Template.mobileCalendar.onCreated ->
	@subscribe 'classes', hidden: yes
	@autorun =>
		date = currentDate()
		handle = undefined
		ids = getUserIds()

		if _.isEmpty ids
			handle = calendarSubs.subscribe(
				'externalCalendarItems'
				date.addDays -1
				date.addDays 2
			)
		else
			handle = calendarSubs.subscribe(
				'foreignCalendarItems'
				ids
				date.addDays -1
				date.addDays 2
			)

		@loading = _.negate handle.ready

Template.mobileCalendar.onRendered ->
	slide 'calendar'
	setPageOptions
		title: 'Agenda'
		color: null

	Meteor.defer ->
		time = +FlowRouter.getParam 'time'
		setDate new Date unless Number.isFinite time

	@$('#datepicker')
		.datetimepicker
			format: 'YYYY-MM-DD'
			inline: true
		.on 'dp.change', (e) ->
			setDate e.date.toDate()
			@parentNode.className = ''

	loading = @loading
	@calendar = calendar = new SwipeView '.mobileCalendar', hastyPageFlip: yes
	getDelta = (index) ->
		[
			[0, 1, -1]
			[-1, 0, 1]
			[1, -1, 0]
		][calendar.currentMasterPage ? 1][index]

	for i in [0..2] then do (i) ->
		Blaze.renderWithData Template.mobileCalendarPage, (->
			delta = getDelta i
			date = currentDate().addDays delta
			ids = getUserIds()

			cursor =
				CalendarItems.find {
					startDate: $gte: date
					endDate: $lte: date.addDays 1
					userIds: $in: (
						if _.isEmpty(ids) then [ Meteor.userId() ]
						else ids
					)
				},
					transform: calendarItemToMobileCalendar
					sort:
						startDate: 1
						endDate: 1

			loading: -> if cursor.count() > 0 then no else loading()
			items: cursor
		), calendar.masterPages[i]

	Mousetrap.bind 'left', ->
		setDateDelta -1
		false

	Mousetrap.bind 'right', ->
		setDateDelta 1
		false

	Mousetrap.bind 'space', ->
		setDate Date.today()
		false

	calendar.onFlip ->
		delta = -calendar.directionX
		setDateDelta delta

Template.mobileCalendar.onDestroyed ->
	@calendar.destroy()
	Mousetrap.unbind [ 'left', 'right', 'space' ]
