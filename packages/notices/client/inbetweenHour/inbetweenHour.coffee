UPDATE_TIME = ms.minutes 20
SHOWN_PERSON_COUNT = 7

lastUpdate = undefined
lastCount = undefined

NoticeManager.provide 'inbetweenHour', ->
	sub = @subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 1
	minuteTracker.depend()

	count = ScheduleFunctions.getInbetweenHours(@userId, yes).length
	lastCount ?= count if sub.ready()
	lastUpdate = _.now()

	call = Call 'inbetweenhours', 'getInbetweenHours'

	if (lastCount? and lastCount isnt count) or _.now() - lastUpdate > UPDATE_TIME
		call.update()
		lastUpdate = _.now()
		lastCount = count

	hours = call.result() ? []
	current = _.find hours, (h) -> h.start <= new Date() <= h.end

	if current?
		@subscribe 'usersData', current.userIds

		template: 'inbetweenHour'
		data: current

		header: 'Tussenuur'
		priority: 3

Template.inbetweenHour.helpers
	taskCount: ->
		userId = Meteor.userId()
		CalendarItems.find({
			'userIds': userId
			'usersDone': $ne: userId
			'content': $exists: yes
			'content.type': $ne: 'information'
			'content.description': $exists: yes
			'type': $ne: 'schoolwide'
			'startDate': $gte: new Date
			'endDate': $lte: Date.today().addDays 1
		}).count()

	persons: ->
		users = Meteor.users.find({
			_id:
				$in: @userIds
				$ne: Meteor.userId()
		}).fetch()
		courseInfo = getUserField Meteor.userId(), 'profile.courseInfo'

		_(users)
			.sortByOrder [
				(u) -> u.profile.courseInfo.year is courseInfo.year
				(u) -> u.profile.courseInfo.schoolVariant is courseInfo.schoolVariant
			], [
				'dec'
				'dec'
			]
			.take SHOWN_PERSON_COUNT
			.value()

	restPersonCount: ->
		count = Meteor.users.find(_id: $in: @userIds).count() - SHOWN_PERSON_COUNT
		Math.max 0, count
