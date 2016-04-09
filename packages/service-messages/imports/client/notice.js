import { Updates } from '../lib/collections.js'

export default function () {
	Meteor.subscribe('updates')
	const updates = Updates.find({}).fetch()

	return updates.map((update) => {
		return {
			id: update._id,
			template: 'updates_notice',
			header: update.header,
			data: update,
		}
	})
}
