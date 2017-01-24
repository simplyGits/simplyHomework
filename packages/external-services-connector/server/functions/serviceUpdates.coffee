import { ExternalServicesConnector, getServices } from '../connector.coffee'
import { serviceUpdateInvalidationTime } from '../constants.coffee'
import { handleCollErr, checkAndMarkUserEvent, fetchConcurrently } from './util.coffee'

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

	results = fetchConcurrently services, 'getUpdates', userId
	for service in services
		{ result, error } = results[service.name]
		if error?
			ExternalServicesConnector.handleServiceError service.name, userId, error
			errors.push error
			continue

		ServiceUpdates.remove {
			userId: userId
			fetchedBy: service.name
		}, handleCollErr
		for update in result
			ServiceUpdates.insert update, handleCollErr

	errors
