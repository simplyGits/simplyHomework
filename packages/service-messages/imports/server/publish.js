import { Updates } from '../lib/collections.js'

Meteor.publish('updates', function () {
	if (this.userId == null) {
		this.ready()
		return
	}

	return Updates.find({
		hidden: false,
	})
})
