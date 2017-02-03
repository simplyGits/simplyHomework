import * as emails from 'simplyemail'
import { Email } from 'meteor/email'

const settingsUrl = Meteor.absoluteUrl('settings/notifications')

function wrap (fn) {
	return function (obj) {
		return Promise.await(fn({
			...obj,
			settingsUrl,
		}))
	}
}

export const cijfer = wrap(emails.cijfer)
export const html = wrap(emails.html)
export const project = wrap(emails.project)

/**
 * @method getHtmlMail
 * @param {String} title
 * @param {String} body
 * @param {Object} [schema]
 * @return {String}
 */
export function getHtmlMail (title, body, schema) {
	check(title, String)
	check(body, String)
	check(schema, Match.Optional(Object))

	body = body.replace(/\n/ig, '<br>')
	return html({ title, body })
}

/**
 * @method sendHtmlMail
 * @param {User|String} user User object or email address
 * @param {String} title
 * @param {String} body
 */
export function sendHtmlMail (user, title, body) {
	check(user, Match.OneOf(Object, String))
	check(title, String)
	check(body, String)

	Email.send({
		from: 'simplyHomework <hello@simplyApps.nl>',
		to: _.isString(user) ? user : user.emails[0].address,
		subject: `simplyHomework | ${title}`,
		html: getHtmlMail(title, body),
	})
}

import './mailSettings.js'
