const sessions = new Mongo.Collection('sessions')

Meteor.users.find({
	'profile.firstName': { $ne: '' },
}, {
	fields: {
		_id: 1,
		'services.resume.loginTokens': 1,
	},
}).observe({
	changed(newDoc, oldDoc) {
		const oldTokens = oldDoc.services.resume.loginTokens
		const newTokens = newDoc.services.resume.loginTokens

		const addedSessions = _.difference(newTokens, oldTokens)
		addedSessions.forEach((session) => {
			sessions.insert({
				hashedToken: session.hashedToken,
				creation: session.when,
				userId: newDoc._id,
			})
		})

		const removedSessions = _.difference(oldTokens, newTokens)
		removedSessions.forEach((session) => {
			sessions.remove({
				hashedToken: session.hashedToken,
			})
		})
	},
})

Meteor.methods({
	'sessions_extend': function (token) {
		this.unblock()
		check(token, String)
		const hashed = Accounts._hashLoginToken(token)
		const session = sessions.findOne({
			hashedToken: hashed,
		})
		if (session == null) {
			throw new Meteor.Error('not-found')
		}

		sessions.update(session._id, {
			$set: {
				ip: this.connection.clientAddress,
				userAgent: this.connection.httpHeaders['user-agent'],
				lastLogin: new Date(),
			},
		})
		return session._id
	},

	'sessions_kill': function (id) {
		check(id, String)
		if (this.userId == null) {
			throw new Meteor.Error('not-logged-in')
		}

		const session = sessions.findOne(id)
		if (session == null) {
			throw new Meteor.Error('not-found')
		}

		Meteor.users.update(this.userId, {
			$pull: {
				'services.resume.loginTokens': {
					hashedToken: session.hashedToken,
				},
			},
		})
	},
})

Meteor.publish('sessions', function () {
	this.unblock()
	if (!this.userId) {
		this.ready()
		return undefined
	}

	return sessions.find({
		userId: this.userId,
	}, {
		fields: {
			hashedToken: 0,
		},
	})
})
