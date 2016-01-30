###*
# @method getDate
# @return {Date}
###
getDate = ->
	Date.today().addDays switch new Date().getDay()
		when 5 then 3
		when 6 then 2
		else 1

###*
# @method getTasks
# @return {Object[]}
###
getTasks = ->
	# TODO: Also mix homework for tommorow and homework for days where the day
	# before has no time. Unless today has no time.

	date = getDate()
	CalendarItems.find({
		'userIds': Meteor.userId()
		'content': $exists: yes
		'content.type': $ne: 'information'
		'content.description': $exists: yes
		'startDate': $gte: date
		'endDate': $lte: date.addDays 1
	}, {
		sort:
			startDate: 1
		transform: (item) ->
			description: item.content.description.replace /\n/g, '; '
			class: -> Classes.findOne item.classId
			date: item.startDate
			done: (d) ->
				Meteor.call 'markCalendarItemDone', item._id, d if d?
				Meteor.userId() in item.usersDone
	}).fetch()

NoticeManager.provide 'tasks', ->
	dateTracker.depend()
	@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 4

	day = Helpers.formatDateRelative getDate(), no

	if getTasks().length > 0
		template: 'tasks'
		header: "Huiswerk voor #{day}"
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
