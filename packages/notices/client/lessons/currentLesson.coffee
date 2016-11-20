NoticeManager.provide 'currentLesson', ->
	minuteTracker.depend()
	@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 1

	currentAppointment = ScheduleFunctions.currentLesson()
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
			queryParams:
				openCalendarItemId: currentAppointment._id
