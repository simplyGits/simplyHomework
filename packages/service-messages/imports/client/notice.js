import { Updates } from '../lib/collections.js'

export default function () {
	Meteor.subscribe('updates')
	const updates = Updates.find({
		hidden: false,
	}).fetch()

	return updates.length > 0 && {
		template: 'updates_notice',
		header: 'simplyHomework service berichten',
		data: updates,
	}
}
