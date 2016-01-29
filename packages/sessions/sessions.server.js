Meteor.startup(function () {
	const sessions = new Mongo.Collection('sessions')

	Meteor.onConnection(function (connection) {
		const headers = connection.httpHeaders
		const useragent = headers && headers['user-agent']

		sessions.insert({
			_id: connection.id,
			useragent: useragent,
			creation: new Date(),
		})

		connection.onClose(function () {
			sessions.remove(connection.id)
		})
	})

	Meteor.methods({
		'sessions_extend': function (id, info) {
			const x = {}
			for (const key in info) {
				x[key] = info[key]
			}
			x.userId = this.userId

			sessions.update(id, {
				$set: x,
			})
		},
	})
})
