recentGrades = ->
	dateTracker.depend()
	date = Date.today().addDays -4
	Grades.find(
		dateFilledIn: $gte: date
		isEnd: no
	).fetch()

NoticeManager.provide 'recentGrades', ->
	sub = Meteor.subscribe 'externalGrades', onlyRecent: yes

	if recentGrades().length
		template: 'recentGrades'
		header: 'Recent behaalde cijfers'
		priority: 0
		ready: -> sub.ready()
	else
		ready: -> sub.ready()

Template.recentGrades.helpers
	gradeGroups: ->
		grades = recentGrades()
		_(grades)
			.sortByOrder 'dateFilledIn', 'desc'
			.uniq 'classId'
			.map (g) ->
				class: g.class()
				grades: (
					_(grades)
						.filter (x) -> x.classId is g.classId
						.sortBy 'dateFilledIn'
						.map (x) -> if x.passed then x.__grade else "<b style='color: red'>#{x.__grade}</b>"
						.join ' & '
				)
			.value()

Template.recentGradeGroup.events
	'click': -> FlowRouter.go 'classView', id: @class._id
