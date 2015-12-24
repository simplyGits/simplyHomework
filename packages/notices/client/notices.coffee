# added temp till we have used `NoticeManager.provide` everywhere.
@notices = notices = NoticeManager.notices

Template.notices.helpers
	notices: -> NoticeManager.get()
	timeGreeting: -> TimeGreeting()

Template.notices.events
	'click .notice': ->
		a = @onClick
		switch a?.action
			when 'route' then FlowRouter.go a.route, a.params, a.queryParams

Template.notices.onCreated ->
	@autorun -> NoticeManager.init()
	@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 4

	@autorun ->
		if tasks().length
			notices.upsert {
				template: 'tasks'
			}, {
					template: 'tasks'
					header: 'Nu te doen'
					priority: 1
			}
		else
			notices.remove template: 'tasks'

	notified = []
	@autorun ->
		return # TODO: doe hier iets mee.
		minuteTracker.depend()
		nextAppointment = CalendarItems.findOne {
			userIds: Meteor.userId()
			startDate: $gte: new Date
			scrapped: false
			schoolHour:
				$exists: yes
				$ne: null
		}, sort: 'startDate': 1
		if nextAppointment?
			timeDiff = nextAppointment.startDate - _.now()

			if timeDiff <= 600000 and nextAppointment._id not in notified
				new Notification "#{nextAppointment.class().name} start in #{~~(timeDiff / 1000 / 60)} minuten"
				notified.push nextAppointment._id

	@autorun ->
		minuteTracker.depend()

		today = CalendarItems.find({
			userIds: Meteor.userId()
			startDate: $gte: Date.today()
			endDate: $lte: Date.today().addDays 1
			scrapped: false
			schoolHour:
				$exists: yes
				$ne: null
		}, sort: 'startDate': 1).fetch()
		tomorrow = CalendarItems.find({
			userIds: Meteor.userId()
			startDate: $gte: Date.today().addDays 1
			endDate: $lte: Date.today().addDays 2
			scrapped: false
			schoolHour:
				$exists: yes
				$ne: null
		}, sort: 'startDate': 1).fetch()

		currentAppointment = _.find today, (a) -> a.startDate < new Date() < a.endDate
		nextAppointmentToday = _.find today, (a) -> new Date() < a.startDate

		foundAppointment = (today.length + tomorrow.length) > 0
		dayOver = not nextAppointmentToday?

		if currentAppointment?
			notices.upsert {
				template: 'infoCurrentAppointment'
			}, {
				template: 'infoCurrentAppointment'
				data: currentAppointment

				header: 'Huidig Lesuur'
				subheader: (
					c = currentAppointment.class()
					c?.name ? currentAppointment.description
				)
				priority: 3

				onClick:
					action: 'route'
					route: 'calendar'
					params:
						time: +Date.today()
			}
		else
			notices.remove template: 'infoCurrentAppointment'

		if nextAppointmentToday?
			notices.upsert {
				template: 'infoNextLesson'
			}, {
				template: 'infoNextLesson'
				data: nextAppointmentToday

				header: 'Volgend Lesuur'
				subheader: (
					c = nextAppointmentToday.class()
					c?.name ? nextAppointmentToday.description
				)
				priority: if Math.abs(_.now() - nextAppointmentToday.startDate) < 300000 then 4 else 2

				onClick:
					action: 'route'
					route: 'calendar'
					params:
						time: +Date.today()
			}
		else
			notices.remove template: 'infoNextLesson'

Template.tasks.helpers
	tasks: -> tasks()

Template.taskRow.events
	'change': (event) ->
		$target = $ event.target
		checked = $target.is ':checked'

		@__isDone checked

Template.infoCurrentAppointment.helpers
	timeLeft: ->
		minuteTracker.depend()
		Helpers.timeDiff new Date(), @endDate

Template.infoNextLesson.helpers
	timeLeft: ->
		minuteTracker.depend()
		Helpers.timeDiff new Date(), @startDate
