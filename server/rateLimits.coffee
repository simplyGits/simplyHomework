Meteor.startup ->
	DDPRateLimiter.addRule {
		type: 'method'
		name: (s) -> s in [ 'changeMail', 'removeAccount' ]
	}, 2, 1000

	for sub in [ 'externalCalendarItems', 'foreignCalendarItems' ]
		DDPRateLimiter.addRule {
			type: 'subscription'
			name: sub
		}, 5, 1000
