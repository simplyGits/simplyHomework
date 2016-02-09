handle = undefined

Template.notices.helpers
	ready: -> handle?.ready()
	notices: -> NoticeManager.get()
	timeGreeting: -> TimeGreeting()

	hover: ->
		if getUserField Meteor.userId(), 'settings.devSettings.noticeAlwaysHoverColor'
			'hover'
		else
			''

Template.notices.events
	'click .notice': ->
		a = @onClick
		switch a?.action
			when 'route' then FlowRouter.go a.route, a.params, a.queryParams

Template.notices.onCreated ->
	@autorun ->
		handle = NoticeManager.run()

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
