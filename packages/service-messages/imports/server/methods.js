/* global userIsInRole */

import { Updates } from '../lib/collections.js'
import Update from '../lib/update.js'

Meteor.methods({
	/**
	 * @method updates_add
	 * @param {String} header
	 * @param {String} body
	 * @param {Object} [query]
	 */
	updates_add(header, body, query = undefined) {
		check(header, String)
		check(body, String)
		check(query, Match.Optional(query))

		if (this.userId == null || !userIsInRole(this.userId, 'admin')) {
			throw new Meteor.Error('not-privileged')
		}

		const update = new Update(header, body, this.userId)
		if (query != null) {
			update.setMatchQuery(query)
		}
		Updates.insert(update)
	},

	/**
	 * @method updates_setHidden
	 * @param {String} updateId
	 * @param {Boolean} hidden
	 */
	updates_setHidden(updateId, hidden) {
		check(updateId, String)
		check(hidden, Boolean)

		if (this.userId == null || !userIsInRole(this.userId, 'admin')) {
			throw new Meteor.Error('not-privileged')
		}

		Updates.update(updateId, {
			$set: { hidden },
		})
	},
})
