/*
 * TODO:
 * 		- Add stuff to kill sessions.
 */

Meteor.startup(function () {
	var sessions = new Mongo.Collection('sessions')
	var currentSession = new ReactiveVar(null)

	var cookies = function () {
		var res = {}
		document.cookie
		.split(/[\s;]+/g)
		.forEach(function (cookie) {
			var splitted = cookie.split('=')
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
				chromeInfo: (chrome && chrome.loadTimes && chrome.loadTimes()),
				loginToken: cookies()['meteor_login_token'],
			}
		)
	})

	Sessions = {
		current: function () {
			return currentSession.get()
		},
		all: function () {
			return sessions.find().fetch()
		},
		others: function () {
			return sessions.find({
				_id: { $ne: currentSession.get()._id }
			}).fetch()
		},
		kill: function (sessionId) {
			console.err('not yet implemented, m8')
		},
	}
})
