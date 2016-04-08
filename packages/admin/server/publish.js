/* global userIsInRole, Counts, ReportItems */

function pub (name, fn) {
	Meteor.publish(`admin_${name}`, function () {
		if (this.userId == null || !userIsInRole(this.userId, 'admin')) {
			this.ready()
			return undefined
		}
		return fn.apply(this, arguments)
	})
}

pub('userCount', function () {
	Counts.publish(
		this,
		'userCount',
		Meteor.users.find({})
	)
})

pub('loggedIn', function () {
	Counts.publish(
		this,
		'loggedInUsersCount',
		Meteor.users.find({ 'status.online': true })
	)
})

pub('reportItems', function (all = false) {
	let query = {}
	if (!all) {
		query = {
			resolvedInfo: { $exists: false },
		}
	}
	return ReportItems.find(query)
})
