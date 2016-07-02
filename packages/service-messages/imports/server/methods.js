/* global userIsInRole */

import { Updates } from '../lib/collections.js'
import Update from '../lib/update.js'

Meteor.methods({
	/**
	 * @method updates_add
	 * @param {Object} options
	 * 	@param {String} options.header
	 * 	@param {String} options.body
	 * 	@param {Object} [options.query]
	 * 	@param {Number} [options.priority=0]
	 * @return {String} The ID of the update.
	 */
	updates_add(options) {
		check(options, Object)
		const { header, body, query, priority = 0 } = options
		check(header, String)
		check(body, String)
		check(query, Match.Optional(Object))
		check(priority, Match.Optional(Number))

		if (this.userId == null || !userIsInRole(this.userId, 'admin')) {
			throw new Meteor.Error('not-privileged')
		}

		const update = new Update(header, body, this.userId)
		if (query != null) {
			update.setMatchQuery(query)
		}
		update.priority = priority
		return Updates.insert(update)
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
