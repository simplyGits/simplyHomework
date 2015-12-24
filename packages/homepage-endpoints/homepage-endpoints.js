'use strict'

WebApp.connectHandlers.use('/api/usercount', function (req, res) {
	const count = Meteor.users.find({}, {
		fields: { _id: 1 },
	}).count()
	res.end('' + count)
})

WebApp.connectHandlers.use('/http/login', function (req, res, next) {
	if (req.method !== 'POST') {
		next()
		return
	}

	// TODO: really get the body from the req. ;)
	const body = '{ "mail": "", "hash": "" }'
	const parsed = JSON.parse(body)

	const user = Accounts.findUserByEmail(parsed.mail)
	if (user == null) {
		res.end('some error, plus set some headers n stuff.')
		return
	}

	const passRes = Accounts._checkPassword(user, {
		digest: parsed.hash,
		algorithm: 'sha-256',
	})

	if (passRes.error != null) {
		res.end('wrong apssword error, set some headers n stuff.')
		return
	}

	const hash = crypto.createHash('sha256')
	hash.update(Random.secret())
	const token = {
		hashedToken: hash.digest('base64'),
		when: new Date,
	}

	Meteor.users.update({
		_id: user._id,
	}, {
		$addToSet: {
			'services.resume.loginTokens': token,
		},
	})

	// TODO: redirect user to /app
})
