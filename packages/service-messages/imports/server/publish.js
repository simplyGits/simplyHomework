/* global createMatcher */

import { Updates } from '../lib/collections.js'

const getMachQuery = (update) => EJSON.parse(update.matchQuery)
const pull = (arr, item) => {
	const index = arr.indexOf(item)
	if (index !== -1) {
		arr.splice(index, 1)
	}
}

Meteor.publish('updates', function () {
	const self = this

	if (self.userId == null) {
		this.ready()
		return
	}
	{
		let user
		const getUser = function () {
			if (user === undefined) {
				user = Meteor.users.findOne(self.userId)
			}
			return user
		}
		var userMatches = (update) => { // eslint-disable-line no-var
			if (update.matchQuery !== '{}') {
				const matcher = createMatcher(getMachQuery(update))
				return matcher(getUser())
			}
			return true
		}
	}

	const current = []
	const cursor = Updates.find({
		hidden: false,
	})
	const observer = cursor.observeChanges({
		added(id, doc) {
			if (userMatches(doc)) {
				self.added('updates', id, doc)
				current.push(id)
			}
		},
		changed(id, doc) {
			const contains = current.includes(id)
			const matches = 'matchQuery' in doc ? userMatches(doc) : contains

			if (matches) {
				if (contains) {
					self.changed('updates', id, doc)
				} else {
					self.added('updates', id, Updates.findOne(id))
					current.push(id)
				}
			} else if (contains) {
				self.removed('updates', id)
				pull(current, id)
			}
		},
		removed(id) {
			if (current.includes(id)) {
				self.removed('updates', id)
				pull(current, id)
			}
		},
	})

	this.onStop(() => observer.stop())
	this.ready()
})
