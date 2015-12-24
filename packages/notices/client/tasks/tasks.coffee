NoticeManager.provide 'tasks', ->
	dateTracker.depend()
	sub = Meteor.subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 4

	if tasks().length
		ready: -> sub.ready()
		template: 'tasks'
		header: 'Nu te doen'
		priority: 1
	else
		ready: -> sub.ready()

Template.tasks.helpers
	tasks: -> tasks()

Template.taskRow.events
	'change': (event) ->
		$target = $ event.target
		checked = $target.is ':checked'

		@__isDone checked
