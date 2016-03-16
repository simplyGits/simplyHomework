Template.grades.helpers
	endGrade: -> GradeFunctions.getEndGrade @_id, Meteor.userId()
	gradeGroups: ->
		arr = GradeFunctions.getClassGrades @_id, Meteor.userId()
		_(arr)
			.reject 'isEnd'
			.map 'period'
			.uniq 'id'
			.map (period) ->
				name: period.name
				grades: (
					_(arr)
						.filter (g) -> g.period.id is period.id
						.sortBy 'dateFilledIn'
						.value()
				)
			.reject (group) -> group.grades.length is 0
			.sortBy (group) -> group.grades[0].dateFilledIn
			.value()

	isLoading: -> not gradesSub.ready()
