Meteor.startup ->
	DDPRateLimiter.addRule {
		type: 'method'
		name: (s) -> s in [ 'changeMail', 'removeAccount' ]
	}, 2, 1000
