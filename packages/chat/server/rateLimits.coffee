Meteor.startup ->
	DDPRateLimiter.addRule {
		type: 'method'
		name: 'addChatMessage'
	}, 15, 10000

	DDPRateLimiter.addRule {
		type: 'method'
		name: 'updateChatMessage'
	}, 4, 1000
