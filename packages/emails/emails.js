import * as emails from 'simplyemail'

const settingsUrl = Meteor.absoluteUrl('settings')

function wrap (fn) {
	return function (obj) {
		return Promise.await(fn({
			...obj,
			settingsUrl,
		}))
	}
}

const exported = {
	cijfer: wrap(emails.cijfer),
	html: wrap(emails.html),
	project: wrap(emails.project),
}

/**
 * @method getMail
 * @param {String} title
 * @param {String} body
 * @param {Object} [schema]
 * @return {String}
 */
getMail = function (title, body, schema) {
	check(title, String)
	check(body, String)
	check(schema, Match.Optional(Object))

	body = body.replace(/\n/ig, '<br>')
	return exported.html({ title, body })
}

/**
 * @method sendMail
 * @param {User|String} user User object or email address
 * @param {String} subject
 * @param {String} body
 */
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

export default exported
