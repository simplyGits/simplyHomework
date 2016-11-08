Meteor.loginWithExternalServices = (username, pass, callback) ->
	Accounts.callLoginMethod
		methodArguments: [{
			username: username
			passHash: Accounts._hashPassword(pass).digest
		}]
		userCallback: (e, r) ->
			if e?
				callback? e
			else
				callback?()
