###*
# @method getTasks
# @return {Object[]}
###
getTasks = ->
	# TODO: Also mix homework for tommorow and homework for days where the day
	# before has no time. Unless today has no time.

	tasks = []
	#for gS in GoaledSchedules.find(dueDate: $gte: new Date).fetch()
	#	tasks.pushMore _.filter gS.tasks, (t) -> EJSON.equals t.plannedDate.date(), Date.today()

	res = []
	res = res.concat CalendarItems.find({
		'userIds': Meteor.userId()
		'content': $exists: yes
		'content.type': $ne: 'information'
		'content.description': $exists: yes
		'startDate': $gte: Date.today().addDays 1
		'endDate': $lte: Date.today().addDays 2
	}, {
		sort:
			startDate: 1
		transform: (item) -> _.extend item,
			__id: item._id
			__taskDescription: item.content.description
			__className: Classes.findOne(item.classId)?.name ? ''
			__isDone: (d) ->
				if d?
					CalendarItems.update item._id, (
						if d then $push: usersDone: Meteor.userId()
						else $pull: usersDone: Meteor.userId()
					)
				Meteor.userId() in item.usersDone
	}).fetch()

	res = res.concat _.map tasks, (task) -> _.extend task,
		__id: task._id.toHexString()
		__taskDescription: task.content
		__className: '' # TODO: Should be set correctly.

	res

NoticeManager.provide 'tasks', ->
	dateTracker.depend()
	@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 4

	if getTasks().length > 0
		template: 'tasks'
		header: 'Nu te doen'
		priority: 1

Template.tasks.helpers
	tasks: -> getTasks()

Template.taskRow.events
	'change': (event) ->
		$target = $ event.target
		checked = $target.is ':checked'

		@__isDone checked
