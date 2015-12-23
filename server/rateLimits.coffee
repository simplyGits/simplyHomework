Meteor.startup ->
	DDPRateLimiter.addRule {
		type: 'method'
		name: 'checkPasswordHash'
	}, 2, 1000
