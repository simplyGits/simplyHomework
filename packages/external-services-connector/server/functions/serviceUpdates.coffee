import { ExternalServicesConnector, getServices } from '../connector.coffee'
import { serviceUpdateInvalidationTime } from '../constants.coffee'
import { handleCollErr, checkAndMarkUserEvent } from './util.coffee'

###*
# @fetchServiceUpdates
# @param {String} userId
# @param {Boolean} [forceUpdate=false]
# @return {Error[]}
###
export fetchServiceUpdates = (userId, forceUpdate = no) ->
	check userId, String
	check forceUpdate, Boolean

	errors = []

	services = getServices userId, 'getUpdates'
	if services.length is 0 or not checkAndMarkUserEvent(
		userId
		'serviceUpdatesUpdate'
		serviceUpdateInvalidationTime
		forceUpdate
	)
		return errors

	for service in services
		try
			updates = service.getUpdates userId
		catch e
			ExternalServicesConnector.handleServiceError service.name, userId, e
			errors.push e
			continue

		ServiceUpdates.remove {
			userId: userId
			fetchedBy: service.name
		}, handleCollErr
		for update in updates
			ServiceUpdates.insert update, handleCollErr

	errors
