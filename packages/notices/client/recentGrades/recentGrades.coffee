recentGrades = ->
	dateTracker.depend()
	date = Date.today().addDays -4
	Grades.find(
		dateFilledIn: $gte: date
		isEnd: no
	).fetch()

NoticeManager.provide 'recentGrades', ->
	@subscribe 'externalGrades', onlyRecent: yes

	if recentGrades().length
		template: 'recentGrades'
		header: 'Recent behaalde cijfers'
		priority: 0

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
						.map (g) ->
							compile = (g) -> Blaze.toHTMLWithData Template.recentGrade, g

							_.chain(g.previousValues)
								.map (old) ->
									old = _.extend new Grade(old.gradeStr), old
									old.__grade = old.toString().replace '.', ','

									"<span class='prev'>#{compile old}</span>"
								.push compile(g)
								.join ' &rarr; '
								.value()
						.join ' &amp; '
				)
			.value()

Template.recentGradeGroup.events
	'click': -> FlowRouter.go 'classView', id: @class._id
