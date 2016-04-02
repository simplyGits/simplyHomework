NoticeManager.provide 'projects', ->
	dateTracker.depend()

	date = Date.today().addDays 5
	projects = Projects.find({
		deadline:
			$lte: date
			$gte: Date.today() # TODO: remove this line when we added a way to mark projects as done
		finished: no
		participants: Meteor.userId()
	}, {
		sort:
			deadline: 1
	}).fetch()

	if projects.length > 0
		template: 'projectsNotice'
		header: 'Projecten met deadlines binnenkort'
		priority: 0
		data: projects

Template['projectsNotice_project'].helpers
	backgroundColor: ->
		diff = @deadline.getTime() - _.now()
		g = Math.round(diff/432000000 * 180)
		g = 0 if g < 0
		"rgb(255, #{g}, 0)"

	class: -> Classes.findOne @classId

Template['projectsNotice_project'].events
	'click': -> FlowRouter.go 'projectView', id: @_id
