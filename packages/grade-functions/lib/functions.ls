@GradeFunctions.get-class-grades = (class-id, user-id = Meteor.user-id!) ->
	check class-id, String
	check user-id, String

	Grades.find(
		owner-id: user-id
		class-id: class-id
	).fetch!

@GradeFunctions.get-end-grade = (class-id, user-id = Meteor.user-id!) ->
	check class-id, String
	check user-id, String

	grades = Grades.find(
		class-id: class-id
		owner-id: user-id
		is-end: yes
	).fetch!
	g = _.find(grades, weight: 0) ? grades[0]

	unless g?
		grades = Grades.find(
			owner-id: user-id
			class-id: class-id
			is-end: no
			grade: $ne: NaN
		).fetch!

		grade-weight-sum = _(grades)
			.map (g) -> g.weight * g.grade
			.sum!
		weight-sum = _(grades)
			.map (g) -> g.weight
			.sum!
		grade = grade-weight-sum / weight-sum

		if _.is-finite grade
			g = new Grade do
				grade
				1
				class-id
				user-id
			g.is-end = yes

			g.__insufficient = if g.passed then '' else 'insufficient'
			g.__grade = g.toString!replace '.', ','

	g

@GradeFunctions.get-all-grades = (only-end = no, user-id = Meteor.user-id!) ->
	check only-end, Boolean
	check user-id, String

	query = owner-id: user-id
	query.is-end = yes if only-end

	Grades.find query .fetch!

get-school-grades = (user-id, grade-id) ->
	check user-id, String
	check grade-id, String

	grade = Grades.find-one do
		_id: grade-id
		owner-id: user-id
	unless grade?
		throw new Meteor.Error \not-found

	Grades.find(
		description: grade.description
		weight: grade.weight
		class-id: grade.class-id
		'period.id': grade.period.id
	).fetch!

###*
# @method gradeClassMean
# @param {String} userId
# @param {String} gradeId
# @return {Number}
###
@GradeFunctions.grade-class-mean = (user-id, grade-id) ->
	check user-id, String
	check grade-id, String

	school-grades = get-school-grades user-id, grade-id
	_(school-grades)
		.filter (g) ->
			c = Classes.find-one g.class-id
			get-class-group(c._id, user-id) is get-class-group(c._id, g.owner-id)
		.pluck \grade
		.compact!
		.mean!
		.value!

###*
# Not really strictly per school, but we match a various amount of parameters to
# be equal, so it's practicaly per school.
#
# @method gradeSchoolMean
# @param {String} userId
# @param {String} gradeId
# @return {Number}
###
@GradeFunctions.grade-school-mean = (user-id, grade-id) ->
	# REVIEW: It's possible (and likely) that different teachers don't use the same
	# description for the same grades (some teachers may use the description
	# 'tw2' and others may use 'pww2'). We have to find a better way to match the
	# grades.

	check user-id, String
	check grade-id, String

	school-grades = get-school-grades user-id, grade-id
	_(school-grades)
		.pluck \grade
		.compact!
		.mean!
		.value!
