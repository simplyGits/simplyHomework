{ functions, Services, AuthError } = require './connector.coffee'

Meteor.methods
	'getModuleInfo': -> functions.getModuleInfo @userId

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

		try
			service.createData params..., @userId
		catch err
			if err instanceof AuthError # incorrect login credentials
				throw new Meteor.Error 'forbidden', 'Login credentials incorrect.'
			else # custom error
				ExternalServicesConnector.handleServiceError service.name, @userId, err
				throw new Meteor.Error 'error', 'Other error.', err.message

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
		functions.getServiceProfileData serviceName, @userId

	'getPersons': (query, type) ->
		check query, String
		check type, Match.OneOf String, null
		functions.getPersons query, type, @userId

	'getExternalPersonClasses': ->
		@unblock()
		functions.getExternalPersonClasses @userId

	'getServiceSchools': (serviceName, query) ->
		@unblock()
		check serviceName, String
		check query, String
		functions.getServiceSchools serviceName, query, @userId

	'getSchools': (query) ->
		@unblock()
		check query, String
		functions.getSchools query, @userId

	'getProfileData': ->
		@unblock()
		functions.getProfileData @userId

	'sendMessage': (subject, body, recipients, service, draftId = undefined) ->
		@unblock()
		check subject, String
		check body, String
		check recipients, [String]
		check service, String
		check draftId, Match.Optional String

		if Helpers.isEmptyString body
			throw new Meteor.Error 'no-content'

		sendMessage subject, body, recipients, service, @userId

		if draftId?
			Drafts.remove
				_id: draftId
				senderId: @userId

		undefined

	'replyMessage': (id, all, body, draftId = undefined) ->
		@unblock()
		check id, String
		check all, Boolean
		check body, String
		check draftId, Match.Optional String

		userId = @userId
		service = _.find Services, (s) -> s.name is 'magister' and s.active userId
		if not service?
			throw new Meteor.Error 'magister-only'

		replyMessage id, all, body, 'magister', userId

		if draftId?
			Drafts.remove
				_id: draftId
				senderId: @userId

		undefined
