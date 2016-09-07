/* global getUserField, checkPasswordHash, Picker */

import QRCode from 'qrcode'
import speakeasy from 'speakeasy'

Accounts.validateLoginAttempt(function ({ type, allowed, user }) {
	if (!allowed) {
		return false
	} else if (type !== 'password') {
		return true
	}

	if (_.get(user, 'settings.devSettings.tfaEnabled')) {
		// force the user to login with the 'tfa_login' method
		throw new Meteor.Error('tfa-required')
	}

	return true
})

Meteor.methods({
	tfa_login(mail, hash, token) {
		check(mail, String)
		check(hash, String)
		check(token, String)

		const user = Meteor.users.findOne({
			emails: { $elemMatch: { address: mail } },
		}, {
			fields: {
				_id: 1,
				emails: 1,
				'tfa.secret': 1,
			},
		})
		if (user == null) {
			throw new Meteor.Error('user-not-found', 'User not found')
		}
		const userId = user._id

		let correct = checkPasswordHash(hash, userId)
		if (!correct) {
			throw new Meteor.Error('incorrect-password', 'Incorrect password')
		}

		correct = speakeasy.totp.verify({
			secret: user.tfa.secret.base32,
			encoding: 'base32',
			token: token,
		})
		if (!correct) {
			throw new Meteor.Error('incorrect-token', 'Provided token is incorrect')
		}

		const loginToken = Accounts._generateStampedLoginToken()
		Accounts._insertLoginToken(userId, loginToken)
		return loginToken
	},
})

Picker.route('/2fa/qr', function (params, req, res) {
	const err = (code, str) => {
		res.writeHead(code, { 'Content-Type': 'text/plain' })
		res.end(str)
	}
	const parseCookies = (str = '') => {
		const res = {}
		str
			.split(/[\s;]+/g)
			.forEach((cookie) => {
				const splitted = cookie.split('=')
				res[splitted[0]] = splitted[1]
			})
		return res
	}

	const cookies = parseCookies(req.headers.cookie)
	const token = cookies['meteor_login_token']
	if (token == null) {
		err(401, 'not logged in')
		return
	}

	const user = Meteor.users.findOne({
		'services.resume.loginTokens.hashedToken': Accounts._hashLoginToken(token),
	}, {
		fields: { _id: 1 },
	})

	const userId = user != null && user._id
	if (userId == null) {
		err(404, 'no user found with provided logintoken')
		return
	}

	const secret = getUserField(userId, 'tfa.secret')
	if (secret == null) {
		err(404, 'no secret found')
		return
	}

	const retrieved = getUserField(userId, 'tfa.retrieved', false)
	if (retrieved) {
		err(400, 'private key already retrieved')
		return
	}

	const draw = Meteor.wrapAsync(QRCode.draw, QRCode)
	const canvas = draw(secret.otpauth_url)

	res.writeHead(200, { 'Content-Type': 'image/png' })
	canvas.pngStream().pipe(res)

	Meteor.users.update(userId, {
		$set: {
			'tfa.retrieved': true,
		},
	})
})

Meteor.startup(function () {
	let loading = true

	Meteor.users.find({
		'settings.devSettings.tfaEnabled': true,
	}).observe({
		added(user) {
			if (loading) return

			const secret = speakeasy.generateSecret({
				length: 32,
				symbols: true,
				otpauth_url: true,
				name: 'simplyHomework',
			})

			Meteor.users.update(user._id, {
				$set: {
					'tfa.secret': secret,
				},
			})
		},

		removed(user) {
			if (loading) return
			Meteor.users.update(user._id, { $unset: { 'tfa': true } })
		},
	})

	loading = false
})
