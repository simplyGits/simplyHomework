Meteor.startup ->
	DDPRateLimiter.addRule {
		type: 'method'
		name: 'addChatMessage'
	}, 4, 5000

	DDPRateLimiter.addRule {
		type: 'method'
		name: 'updateChatMessage'
	}, 4, 1000
