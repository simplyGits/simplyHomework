import { Updates } from '../lib/collections.js'

export default function () {
	this.subscribe('updates')
	const updates = Updates.find({}).fetch()

	return updates.map((update) => {
		return {
			id: update._id,
			header: update.header,
			subheader: update.subheader,
			template: 'updates_notice',
			priority: update.priority,
			data: update,
		}
	})
}
