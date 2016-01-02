NoticeManager.provide 'currentLesson', ->
	minuteTracker.depend()
	@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 1

	today = CalendarItems.find({
		userIds: Meteor.userId()
		startDate: $gte: Date.today()
		endDate: $lte: Date.today().addDays 1
		scrapped: false
		schoolHour:
			$exists: yes
			$ne: null
	}, sort: 'startDate': 1).fetch()
	currentAppointment = _.find today, (a) -> a.startDate < new Date() < a.endDate

	if currentAppointment?
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

Template.infoCurrentAppointment.helpers
	timeLeft: ->
		minuteTracker.depend()
		Helpers.timeDiff new Date(), @endDate
