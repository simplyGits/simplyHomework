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
							newGrade = Blaze.toHTMLWithData Template.recentGrade, g

							if g.previousValues?
								g = g.previousValues
								g = _.extend new Grade(g.gradeStr), g
								g.__grade = g.toString().replace '.', ','

								oldGrade = Blaze.toHTMLWithData(
									Template.recentGrade
									_.extend new Grade(g.gradeStr), g
								)

								"<span class='prev'>#{oldGrade}</span> &rarr; #{newGrade}"
							else
								newGrade
						.join ' &amp; '
				)
			.value()

Template.recentGradeGroup.events
	'click': -> FlowRouter.go 'classView', id: @class._id
