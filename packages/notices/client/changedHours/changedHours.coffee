getChangedHours = ->
	dayOver = ScheduleFunctions.currentDayOver()
	CalendarItems.find({
		userIds: Meteor.userId()
		startDate: $gte: Date.today().addDays if dayOver then 1 else 0
		scrapped: no
		updateInfo: $exists: yes

		schoolHour:
			$exists: yes
			$ne: null
	}, {
		sort:
			startDate: 1
	}).fetch()

NoticeManager.provide 'changedHours', ->
	minuteTracker.depend()
	# REVIEW the date range here.
	@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 4

	changedHours = getChangedHours()

	if changedHours.length > 0
		template: 'changedHours'
		header: 'Leswijzigingen'
		priority: (
			hasOneToday = _.any changedHours, (item) ->
				item.startDate.date().getTime() is Date.today().getTime()

			if hasOneToday then 2
			else 0
		)

Template.changedHours.helpers
	hourGroups: ->
		arr = getChangedHours()
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

Template.changedHour.helpers
	name: -> @class()?.name ? @description

Template.changedHour.events
	'click': (event, template) ->
		FlowRouter.go(
			'calendar'
			{ time: template.data.startDate.date().getTime() }
			{ openCalendarItemId: template.data._id }
		)

Template['changedHour_diffItem'].helpers
	friendlyKey: ->
		switch @key
			when 'location' then 'Locatie'
			when 'schoolHour' then 'Schooluur'
			when 'startDate' then 'Begin'
			when 'endDate' then 'Eind'
			when 'description' then 'Beschrijving'
			when 'fullDay' then 'Hele dag'
			else Helpers.cap @key
