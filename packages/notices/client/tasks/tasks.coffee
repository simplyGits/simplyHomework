###*
# @method getTasks
# @return {Object[]}
###
getTasks = ->
	# TODO: Also mix homework for tommorow and homework for days where the day
	# before has no time. Unless today has no time.

	delta = switch new Date().getDay()
		when 5 then 3
		when 6 then 2
		else 1

	CalendarItems.find({
		'userIds': Meteor.userId()
		'content': $exists: yes
		'content.type': $ne: 'information'
		'content.description': $exists: yes
		'startDate': $gte: Date.today().addDays delta
		'endDate': $lte: Date.today().addDays delta + 1
	}, {
		sort:
			startDate: 1
		transform: (item) ->
			description: item.content.description
			class: -> Classes.findOne item.classId
			date: item.startDate
			done: (d) ->
				Meteor.call 'markCalendarItemDone', item._id, d if d?
				Meteor.userId() in item.usersDone
	}).fetch()

NoticeManager.provide 'tasks', ->
	dateTracker.depend()
	@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 4

	if getTasks().length > 0
		template: 'tasks'
		header: 'Nu te doen'
		priority: 1

Template.tasks.helpers
	tasks: -> getTasks()

Template.taskRow.helpers
	__done: -> if @done() then 'done' else ''
	__checked: -> if @done() then 'checked' else ''

Template.taskRow.events
	'change': (event) ->
		$target = $ event.target
		checked = $target.is ':checked'

		@done checked
