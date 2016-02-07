const sessions = new Mongo.Collection('sessions')
const currentSessionId = new ReactiveVar()

Tracker.autorun(function () {
	Meteor.connection._userIdDeps.depend()
	Meteor.defer(function () {
		const token = localStorage.getItem('Meteor.loginToken')
		if (token != null) {
			Meteor.call(
				'sessions_updateLastLogin',
				token,
				function (e, r) {
					currentSessionId.set(r)
				}
			)
		}
	})
})

Tracker.autorun(function () {
	if (Meteor.userId() != null) {
		Meteor.subscribe('sessions')
	}
})

Sessions = {
	all() {
		return sessions.find().fetch()
	},
	current() {
		return sessions.findOne(currentSessionId.get())
	},
	others() {
		return sessions.find({
			_id: { $ne: currentSessionId.get() },
		}).fetch()
	},
	kill(sessionId, callback) {
		Meteor.call('sessions_kill', sessionId, callback)
	},
}
