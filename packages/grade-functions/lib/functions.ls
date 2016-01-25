@GradeFunctions.get-class-grades = (class-id, user-id = Meteor.user-id!) ->
	check class-id, String
	check user-id, String

	Grades.find(
		owner-id: user-id
		class-id: class-id
	).fetch!

@GradeFunctions.get-end-grade = (class-id, user-id = Meteor.user-id!) ->
	# TODO: add fallback for when endGrade couldn't be found.
	check class-id, String
	check user-id, String

	Grades.find-one do
		class-id: class-id
		owner-id: user-id
		is-end: yes

@GradeFunctions.get-all-grades = (only-end = no, user-id = Meteor.user-id!) ->
	check only-end, Boolean
	check user-id, String

	query = owner-id: user-id
	query.is-end = yes if only-end

	Grades.find query .fetch!
