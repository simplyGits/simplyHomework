Meteor.startup(function () {
	var sessions = new Mongo.Collection('sessions')

	Meteor.onConnection(function (connection) {
		var headers = connection.httpHeaders
		var useragent = headers && headers['user-agent']

		sessions.insert({
			_id: connection.id,
			useragent: useragent,
		})

		connection.onClose(function () {
			sessions.remove(connection.id)
		})
	})

	Meteor.methods({
		'sessions_extend': function (id, info) {
			var x = {}
			for (key in info) {
				x[key] = info[key]
			}
			x.userId = this.userId

			sessions.update(id, {
				$set: x
			})
		}
	})
})
