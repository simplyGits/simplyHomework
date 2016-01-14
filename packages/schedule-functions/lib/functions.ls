@ScheduleFunctions.get-inbetween-hours = (userId = Meteor.userId!) ->
	res = []
	hours = CalendarItems.find(
		userIds: userId
		startDate: $gte: Date.today!
		endDate: $lte: Date.today!addDays 7
		schoolHour:
			$exists: yes
			$ne: null
	).fetch!

	for daydelta from 0 til 7
		date = Date.today!addDays daydelta
		items = _(hours)
			.filter (item) -> item.startDate.date!getTime! is date.getTime!
			.sortBy 'startDate'
			.value!

		if items.length > 0
			# REVIEW: Use mean?
			timeThreshold = items.0.endDate.getTime! - items.0.startDate.getTime!

			endPrev = undefined
			for item in items
				timeSpan = if endPrev?
					then item.startDate.getTime! - endPrev.getTime!
					else 0
				amount = Math.floor (timeSpan / timeThreshold)
				for i from 0 til amount
					res.push do
						start: new Date (endPrev.getTime! + timeThreshold * i)
						end: new Date (endPrev.getTime! + timeThreshold * ( 1 + i ))

				endPrev = item.endDate

	res

@ScheduleFunctions.current-day-over = (userId = Meteor.userId!) ->
	minuteTracker?depend!
	CalendarItems.find(
		userIds: userId
		startDate: $gte: new Date!
		endDate: $lte: Date.today!addDays 1
		scrapped: false
		schoolHour:
			$exists: yes
			$ne: null
	).count! is 0

@ScheduleFunctions.lessons-for-date = (userId = Meteor.userId!, date = new Date!) ->
	dateTracker?depend!
	date = date.date!
	CalendarItems.find do
		userIds: userId
		startDate: $gte: new Date!
		endDate: $lte: Date.today!addDays 1
		scrapped: false
		schoolHour:
			$exists: yes
			$ne: null
