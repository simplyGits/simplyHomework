Search.provide 'users', ({ user }) ->
	Meteor.users.find({
		'profile.firstName': $ne: ''
		'profile.schoolId': user.profile.schoolId
	}, {
		fields:
			profile: 1

		transform: (u) -> _.extend u,
			type: 'user'
			title: "#{u.profile.firstName} #{u.profile.lastName}"
	}).fetch()
