NoticeManager.provide 'tasks', ->
	dateTracker.depend()
	@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 4

	if tasks().length
		template: 'tasks'
		header: 'Nu te doen'
		priority: 1

Template.tasks.helpers
	tasks: -> tasks()

Template.taskRow.events
	'change': (event) ->
		$target = $ event.target
		checked = $target.is ':checked'

		@__isDone checked
