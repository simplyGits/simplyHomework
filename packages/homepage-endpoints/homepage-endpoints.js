'use strict'

WebApp.connectHandlers.use('/api/usercount', function (req, res) {
	const count = Meteor.users.find({}, {
		fields: { _id: 1 },
	}).count()
	res.end('' + count)
})
