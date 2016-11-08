###*
# A static class that connects to and retrieves data from
# external services (eg. Magister).
#
# @class ExternalServicesConnector
# @static
###
class ExternalServicesConnector
	@services: []

	@pushExternalService: (service) =>
		if _.some(@services, name: service.name)
			throw new Error "Already a service with name '#{service.name}' added"

		@services.push service

exports.ExternalServicesConnector = ExternalServicesConnector
exports.Services = ExternalServicesConnector.services # Just a shortcut.
exports.ServiceInfos = new Mongo.Collection 'services'
_.extend exports, require '../lib/errors.coffee'
require './accounts.coffee'
