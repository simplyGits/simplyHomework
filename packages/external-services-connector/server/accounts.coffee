{ Services } = require './connector.coffee'

Accounts.registerLoginHandler 'externalServices', ({ username, passHash }) ->
	unless username? and passHash?
		return undefined

	services = _.filter Services, 'validateLoginAttempt'

	for service in services
		userId = service.validateLoginAttempt username, passHash

		if userId?
			Analytics.insert
				type: 'login'
				loginHandler: 'externalServices'
				date: new Date
				userId: userId
				service: service.name

			return { userId }

	throw new Meteor.Error 403, 'User not found'
