NoticeManager.provide 'nextLesson', ->
	minuteTracker.depend()
	@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 1

	nextAppointmentToday = ScheduleFunctions.nextLesson()
	if nextAppointmentToday?
		template: 'infoNextLesson'
		data: nextAppointmentToday

		header: 'Volgend Lesuur'
		subheader: (
			c = nextAppointmentToday.class()
			c?.name ? nextAppointmentToday.description
		)
		priority: (
			if 0 < nextAppointmentToday.startDate - _.now() < ms.minutes 5
				4
			else
				2
		)

		onClick:
			action: 'route'
			route: 'calendar'
			params:
				time: +Date.today()
			queryParams:
				openCalendarItemId: nextAppointmentToday._id

Template.infoNextLesson.helpers
	timeLeft: ->
		minuteTracker.depend()
		Helpers.timeDiff new Date(), @startDate
