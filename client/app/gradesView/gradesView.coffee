# TODO: real groups: add ability to add groups and try to make groups
# automatically

# TODO: add way to filter on begin and end dates of grades.

getGradeType = (g) ->
	if g < 5.5
		'danger'
	else if 5.5 <= g < 6 # REVIEW: what should the upper limit be?
		'warning'
	else
		'success'

getAllClasses = ->
	Classes.find({}, {
		sort:
			name: 1
	}).fetch()

selectedClassIds = -> FlowRouter.getQueryParam('classIds') ? []
shownClassIds = ->
	ids = selectedClassIds()
	if ids.length > 0
		ids
	else
		getAllClasses().map (c) -> c._id
getClasses = ->
	selectedIds = selectedClassIds()
	shownIds = shownClassIds()

	_.chain(getAllClasses())
		.map (c) ->
			c.selected = c._id in selectedIds
			c.shown = c._id in shownClassIds
			c.endGrade = ->
				res = GradeFunctions.getEndGrade c._id, Meteor.userId()
				res.__type = getGradeType res.grade
				res
			c
		.filter (c) -> Grades.find(classId: c._id).count() > 0
		.value()

Template.gradesView.onCreated ->
	@subscribe 'externalGrades'

Template.gradesView.onRendered ->
	slide 'grades'
	setPageOptions
		title: 'Cijfers'
		color: null

Template.gradesView.helpers
	classes: getClasses
	groups: ->
		arr = Grades.find({
			classId: $in: shownClassIds()
			isEnd: no
			grade: $ne: NaN # REVIEW: is this needed?
		}, {
			sort:
				dateFilledIn: 1
		}).fetch()

		_(arr)
			.map 'period'
			.uniq 'id'
			.map (period) ->
				grades = (
					_(arr)
						.filter (g) -> g.period.id is period.id
						.sortBy 'dateFilledIn'
						.value()
				)

				name: period.name
				visible: new ReactiveVar yes
				grades: grades
				mean: (
					gradeWeightSum = _(grades)
						.map (g) -> g.weight * g.grade
						.sum()
					weightSum = _(grades)
						.map (g) -> g.weight
						.sum()

					g = gradeWeightSum / weightSum
					unless _.isNaN g
						grade: g.toPrecision(2).replace '.', ','
						type: getGradeType g
				)
			.sortBy (group) -> group.grades[0].dateFilledIn
			.value()

Template.gradesView_class.events
	'change': (event) ->
		current = selectedClassIds()
		FlowRouter.withReplaceState =>
			FlowRouter.setQueryParams
				classIds: (
					if event.target.checked
						current.push @_id
						current
					else
						_.without current, @_id
				)

Template.gradesView_group.helpers
	visible: -> @visible.get()

Template.gradesView_group.events
	'click .header': ->
		current = @visible.get()
		@visible.set not current

Template.gradesView_grade.helpers
	expanded: -> Template.instance()._expanded.get()
	isLoading: -> Template.instance()._isLoading.get()
	means: -> Template.instance()._means.get()

Template.gradesView_grade.events
	'click': (event, instance) ->
		current = instance._expanded.get()
		next = not current

		instance._expanded.set next

		if next is no or
		instance._isLoading.get() or
		instance._means.get()?
			return

		instance._isLoading.set yes
		Meteor.call 'gradeMeans', @_id, (e, r) =>
			instance._isLoading.set no

			return if e?
			obj = {}

			for key in [ 'class', 'school' ]
				val = r[key]
				unless _.isNaN val
					obj[key] = val.toPrecision 2

			instance._means.set obj

Template.gradesView_grade.onCreated ->
	@_expanded = new ReactiveVar no
	@_isLoading = new ReactiveVar no
	@_means = new ReactiveVar undefined
