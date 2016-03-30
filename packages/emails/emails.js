/* global getMail */

import Future from 'fibers/future'
import * as emails from 'simplyemail'

const settingsUrl = Meteor.absoluteUrl('settings')

/**
 * @function wrapPromise
 * @param {Promise} promise
 * @return {any}
 */
function wrapPromise (promise) {
	const fut = new Future()
	promise
		.then((r) => fut.return(r))
		.catch((e) => fut.throw(e))
	return fut.wait()
}


getMail = function (title, body, schema) {
	check(title, String)
	check(body, String)
	check(schema, Match.Optional(Object))

	body = body.replace(/\n/ig, '<br>')
	return wrapPromise(emails.html({ title, body, settingsUrl }))
}

sendMail = function (user, subject, body) {
	check(user, Match.OneOf(Object, String))
	check(subject, String)
	check(body, String)

	Email.send({
		from: 'simplyHomework <hello@simplyApps.nl>',
		to: _.isString(user) ? user : user.emails[0].address,
		subject: `simplyHomework | ${subject}`,
		html: getMail(subject, body),
	})
}

function wrap (fn) {
	return function (obj) {
		return wrapPromise(fn({
			...obj,
			settingsUrl,
		}))
	}
}

export default {
	cijfer: wrap(emails.cijfer),
	html: wrap(emails.html),
	project: wrap(emails.project),
}
