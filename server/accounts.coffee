Accounts.validateLoginAttempt ({ type, allowed, user }) ->
	if allowed and user? and
	type not in [ 'externalServices' ]
		Analytics.insert
			type: 'login'
			loginHandler: type
			date: new Date
			userId: user._id

	allowed
