{ Services } = require './connector.coffee'

Accounts.registerLoginHandler 'externalServices', ({ username, passHash }) ->
	services = _.filter Services, 'validateLoginAttempt'
	for service in services
		userId = service.validateLoginAttempt username, passHash
		return { userId } if userId?

	throw new Meteor.Error 403, 'User not found'
