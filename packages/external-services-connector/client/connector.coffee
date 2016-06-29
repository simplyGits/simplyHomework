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
# Just a shortcut.
exports.Services = ExternalServicesConnector.services
