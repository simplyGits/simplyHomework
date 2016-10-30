###*
# A static class that connects to and retrieves data from
# external services (eg. Magister).
#
# @class ExternalServicesConnector
# @static
###
class ExternalServicesConnector
	@services: []

	@pushExternalService: (module) =>
		@services.push module

exports.ExternalServicesConnector = ExternalServicesConnector
exports.Services = ExternalServicesConnector.services # Just a shortcut.
exports.ServiceInfos = new Mongo.Collection 'services'
_.extend exports, require '../lib/errors.coffee'
