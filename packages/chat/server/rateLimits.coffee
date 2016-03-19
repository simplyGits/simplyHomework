Meteor.startup ->
	DDPRateLimiter.addRule {
		type: 'method'
		name: 'addChatMessage'
	}, 10, 7500

	DDPRateLimiter.addRule {
		type: 'method'
		name: 'updateChatMessage'
	}, 4, 1000
