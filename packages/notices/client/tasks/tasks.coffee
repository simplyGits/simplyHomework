getTasksForDate = (date) ->
	CalendarItems.find({
		'userIds': Meteor.userId()
		'content': $exists: yes
		'content.type': $ne: 'information'
		'content.description': $exists: yes
		'type': $ne: 'schoolwide'
		'startDate': $gte: date
		'endDate': $lte: date.addDays 1
	}, {
		sort:
			startDate: 1
		transform: (item) ->
			description: (
				description = item.content.description
				Helpers.oneLine Helpers.convertLinksToAnchor(description)
			)
			class: -> Classes.findOne item.classId
			date: item.startDate
			done: (d) ->
				if d?
					ga 'send', 'event', 'tasks notice', 'switch calendarItem done state'
					Meteor.call 'markCalendarItemDone', item._id, d
				Meteor.userId() in item.usersDone
			__type: Helpers.cap (
					type = item.content?.type
					if type in [ 'test', 'exam', 'quiz', 'oral' ]
						"#{CalendarItem.contentTypeLong type} "
					else
						''
			)
	}).fetch()

###*
# @method getTasks
# @return {mixed[]}
###
getTasks = ->
	# TODO: Also mix homework for tommorow and homework for days where the day
	# before has no time. Unless today has no time.

	dateTracker.depend()
	startDate = Date.today().addDays switch new Date().getDay()
		when 5 then 3
		when 6 then 2
		else 1

	for i in [0...5]
		date = startDate.addDays i
		tasks = getTasksForDate date
		return [ date, tasks ] if tasks.length > 0

	[ undefined, [] ]

NoticeManager.provide 'tasks', ->
	@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 4

	[ date, tasks ] = getTasks()

	if tasks.length > 0
		template: 'tasks'
		header: "Huiswerk voor #{Helpers.formatDateRelative date, no}"
		data: tasks
		priority: 2

NoticeManager.provide 'tasks today', ->
	@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 1

	tasks = _.filter getTasksForDate(Date.today()), (t) -> new Date < t.date

	if tasks.length > 0
		template: 'tasks'
		header: "Huiswerk voor komende lessen vandaag"
		data: tasks
		priority: 1

Template.taskRow.helpers
	__done: -> if @done() then 'done' else ''
	__checked: -> if @done() then 'checked' else ''

Template.taskRow.events
	'change': (event) ->
		$target = $ event.target
		checked = $target.is ':checked'

		@done checked
