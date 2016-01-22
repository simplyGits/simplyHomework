getScrappedHours = ->
	dayOver = ScheduleFunctions.currentDayOver()
	CalendarItems.find({
		userIds: Meteor.userId()
		startDate: $gte: Date.today().addDays if dayOver then 1 else 0
		scrapped: yes

		schoolHour:
			$exists: yes
			$ne: null
	}, {
		sort:
			startDate: 1
	}).fetch()

NoticeManager.provide 'scrappedHours', ->
	minuteTracker.depend()
	# REVIEW the date range here.
	@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 4

	scrappedHours = getScrappedHours()

	if scrappedHours.length > 0
		template: 'scrappedHours'
		header: 'Uitval'
		priority: (
			hasOneToday = _.any scrappedHours, (item) ->
				item.startDate.date().getTime() is Date.today().getTime()

			if hasOneToday then 2
			else 0
		)

Template.scrappedHours.helpers
	hourGroups: ->
		arr = getScrappedHours()
		_(arr)
			.uniq (h) -> h.startDate.date().getTime()
			.map (h) ->
				today = h.startDate.date().getTime() is Date.today().getTime()

				day: Helpers.cap Helpers.formatDateRelative h.startDate, no
				today: if today then 'today' else ''
				hours: (
					_(arr)
						.filter (x) -> x.startDate.date().getTime() is h.startDate.date().getTime()
						.value()
				)
			.reject (day) -> day.hours.length is 0
			.value()

Template.scrappedHour.helpers
	name: -> @class()?.name ? @description

Template.scrappedHour.events
	'click': ->
		FlowRouter.go(
			'calendar'
			{ time: @startDate.date().getTime() }
			{ openCalendarItemId: @_id }
		)
