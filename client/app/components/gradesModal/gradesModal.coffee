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

Template.grades.onCreated ->
	@subscribe 'externalGrades', classId: @data._id

Template.gradeRow.onCreated ->
	@data._expanded = new ReactiveVar false
	@data._means = new ReactiveVar undefined

Template.gradeRow.helpers
	means: -> @_means.get()
	expanded: -> if @_expanded.get() then 'expanded' else ''

Template.gradeRow.events
	'click': (event, template) ->
		template.data._expanded.set not template.data._expanded.get()

		unless template.data._means.get()?
			Meteor.call 'gradeMeans', @_id, (e, r) ->
				unless e?
					template.data._means.set
						class: r.class.toPrecision 2
						school: r.school.toPrecision 2
