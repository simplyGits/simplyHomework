/* global Helpers, Workers */

import usage from 'usage'
const lookup = Meteor.wrapAsync(usage.lookup, usage)

// when we actually have multiple workers this should be determined in a way.
const WORKER_ID = 1
const POLL_INTERVAL = 1000 * 5 // 5 seconds

Workers = new Mongo.Collection('admin_workers')

const options = {
	keepHistory: true,
}
const pid = process.pid

Meteor.startup(function () {
	let workerId
	const worker = Workers.findOne({
		workerId: WORKER_ID,
	})
	if (worker !== undefined) {
		workerId = worker._id
	} else {
		workerId = Workers.insert({
			workerId: WORKER_ID,
			pid,
			onlineSince: new Date(),
		})
	}

	Helpers.interval(function () {
		let info
		try {
			info = lookup(pid, options)
		} catch (e) {
			console.error('error when looking up process info.', e)
			return
		}

		Workers.update(workerId, {
			status: {
				on: new Date(),
				memory: info.memory,
				cpu: info.cpu,
			},
		})
	}, POLL_INTERVAL)
})
