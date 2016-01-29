/*
 * TODO:
 * 		- Add stuff to kill sessions.
 */

Meteor.startup(function () {
	const sessions = new Mongo.Collection('sessions')
	const currentSession = new ReactiveVar(null)

	const cookies = function () {
		const res = {}
		document.cookie
			.split(/[\s;]+/g)
			.forEach(function (cookie) {
				const splitted = cookie.split('=')
				res[splitted[0]] = splitted[1]
			})
		return res
	}

	Tracker.autorun(function () {
		Meteor.connection._userIdDeps.depend()
		Meteor.call(
			'sessions_extend',
			Accounts.connection._lastSessionId,
			{
				loginToken: cookies()['meteor_login_token'],
			}
		)
	})

	Sessions = {
		current() {
			return currentSession.get()
		},
		all() {
			return sessions.find().fetch()
		},
		others() {
			return sessions.find({
				_id: { $ne: currentSession.get()._id },
			}).fetch()
		},
		kill(sessionId) {
			console.err('not yet implemented, m8')
		},
	}
})
