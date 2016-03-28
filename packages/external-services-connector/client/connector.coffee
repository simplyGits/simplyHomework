###*
# A static class that connects to and retrieves data from
# external services (eg. Magister).
#
# @class ExternalServicesConnector
# @static
###
class ExternalServicesConnector
	@externalServices: []

	@pushExternalService: (module) =>
		@externalServices.push module

@ExternalServicesConnector = ExternalServicesConnector
