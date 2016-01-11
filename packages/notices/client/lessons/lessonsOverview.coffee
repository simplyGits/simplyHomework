getItems = ->
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

	show = (
		if today.length > 0 and new Date() < today[0].startDate
			'today'
		else if tomorrow.length > 0 and (today.length is 0 or new Date() > _.last(today).endDate)
			'tomorrow'
	)
	if show?
		[ (if show is 'today' then today else tomorrow), show ]

NoticeManager.provide 'lessonsOverview', ->
	minuteTracker.depend()
	@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 2

	data = getItems()
	if data? and data[0].length > 0
		template: 'lessonsOverview'

		header: "Lessen van #{if data[1] is 'today' then 'vandaag' else 'morgen'}"
		priority: 0

		onClick:
			action: 'route'
			route: 'calendar'
			params:
				time: +Date.today().addDays if data[1] is 'today' then 0 else 1

Template.lessonsOverview.helpers
	items: ->
		items = getItems()[0]
		_.reject items, (item) -> item.class().__classInfo.hidden

	hidden: ->
		items = getItems()[0]
		_.filter(items, (item) -> item.class().__classInfo.hidden).length
