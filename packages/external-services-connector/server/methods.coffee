Meteor.methods
	'getModuleInfo': -> getModuleInfo @userId

	# REVIEW: should we have checks to ensure that no data has been stored yet for
	# the service?
	#
	# I don't know if it's useful to call this function while there's
	# already data (maybe if an user wants to relogin on another account for
	# example, or we need to do some weird db management which isn't really
	# possible on another way, than to relogin everybody on the services).
	#
	# But it can also make the code less error prone, idk. The best thing to do
	# now is to make Service#createData for each service not break stuff if it's
	# called multiple times on the same user.
	'createServiceData': (serviceName, params...) ->
		@unblock()

		check serviceName, String

		service = _.find Services, (s) -> s.name is serviceName
		unless service?
			throw new Meteor.Error 'notfound', "No module with the name '#{serviceName}' found."

		res = service.createData params..., @userId

		if _.isError res # custom error
			throw new Meteor.Error 'error', 'Other error.', res.message
			ExternalServicesConnector.handleServiceError service.name, @userId, res

		else if not service.loginNeeded # res is true if service is active.
			service.active @userId, res

		else if res is false # login credentials wrong.
			throw new Meteor.Error 'forbidden', 'Login credentials incorrect.'

		Meteor.call 'getServiceProfileData', serviceName, @userId

	'deleteServiceData': (serviceName) ->
		@unblock()

		check serviceName, String

		service = _.find Services, (s) -> s.name is serviceName
		if service?
			service.storedInfo @userId, null
		else
			throw new Meteor.Error 'notfound', "No module with the name '#{serviceName}' found."

	'getServiceProfileData': (serviceName) ->
		check serviceName, String
		getServiceProfileData serviceName, @userId

	'getExternalClasses': ->
		@unblock()
		getExternalClasses @userId

	'getServiceSchools': (serviceName, query) ->
		@unblock()
		check serviceName, String
		check query, String
		getServiceSchools serviceName, query, @userId

	'getSchools': (query) ->
		@unblock()
		check query, String
		getSchools query, @userId

	'getProfileData': ->
		@unblock()
		getProfileData @userId

	'getMessages': (folder, amount) ->
		@unblock()
		check folder, String
		check amount, Number

		userId = @userId
		service = _.find Services, (s) -> s.name is 'magister' and s.active userId
		if not service?
			throw new Meteor.Error 'magister-only'

		getMessages folder, 0, amount, userId

	'fillMessage': (message) ->
		@unblock()
		check message, Object

		userId = @userId
		service = _.find Services, (s) -> s.name is 'magister' and s.active userId
		if not service?
			throw new Meteor.Error 'magister-only'

		fillMessage message, 'magister', userId

	'composeMessage': (subject, body, recipients) ->
		@unblock()
		check subject, String
		check body, String
		check recipients, [String]

		userId = @userId
		service = _.find Services, (s) -> s.name is 'magister' and s.active userId
		if not service?
			throw new Meteor.Error 'magister-only'

		composeMessage subject, body, recipients, 'magister', userId

	'replyMessage': (body, id, all) ->
		@unblock()
		check body, String
		check id, Number
		check all, Boolean

		userId = @userId
		service = _.find Services, (s) -> s.name is 'magister' and s.active userId
		if not service?
			throw new Meteor.Error 'magister-only'

		replyMessage body, id, all, 'magister', userId
