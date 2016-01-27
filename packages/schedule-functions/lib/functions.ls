@ScheduleFunctions.get-inbetween-hours = (user-id = Meteor.user-id!) ->
	res = []
	hours = CalendarItems.find(
		user-ids: user-id
		start-date: $gte: Date.today!
		end-date: $lte: Date.today!add-days 7
		school-hour:
			$exists: yes
			$ne: null
	).fetch!

	for daydelta from 0 til 7
		date = Date.today!add-days daydelta
		items = _(hours)
			.filter (item) -> item.start-date.date!get-time! is date.get-time!
			.sort-by \startDate
			.value!

		if items.length > 0
			# REVIEW: Use mean?
			time-threshold = items.0.end-date.get-time! - items.0.start-date.get-time!

			end-prev = undefined
			for item in items
				time-span = if end-prev?
					then item.start-date.get-time! - end-prev.get-time!
					else 0
				amount = Math.floor (time-span / time-threshold)
				for i from 0 til amount
					res.push do
						start: new Date (end-prev.get-time! + time-threshold * i)
						end: new Date (end-prev.get-time! + time-threshold * ( 1 + i ))

				end-prev = item.end-date

	res

@ScheduleFunctions.current-day-over = (user-id = Meteor.user-id!) ->
	minuteTracker?depend!
	CalendarItems.find(
		user-ids: user-id
		end-date:
			$gte: new Date
			$lte: Date.today!add-days 1
		scrapped: false
		school-hour:
			$exists: yes
			$ne: null
	, fields: _id: 1).count! is 0

@ScheduleFunctions.lessons-for-date = (user-id = Meteor.user-id!, date = new Date!) ->
	dateTracker?depend!
	date .= date!
	CalendarItems.find(
		user-ids: user-id
		start-date: $gte: new Date
		end-date: $lte: Date.today!add-days 1
		scrapped: false
		school-hour:
			$exists: yes
			$ne: null
	).fetch!
