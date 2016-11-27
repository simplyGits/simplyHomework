import { Services, ExternalServicesConnector } from '../connector.coffee'

export getServiceProfileData = (serviceName, userId) ->
	check serviceName, String
	check userId, String

	service = _.find Services, (s) -> name: serviceName

	unless service?
		throw new Meteor.Error 'service-not-found', "No service with name '#{serviceName}' found"
	unless service.getProfileData?
		return undefined

	try
		service.getProfileData userId
	catch e
		ExternalServicesConnector.handleServiceError service.name, userId, e
		e

###*
# Gets the profile data for every enabled external service as an object. Key
# is set to the dbname of the service, the value is set to the profile data of
# that service.
#
# @method getProfileData
# @param userId {String} The ID of the user to get the profile data for.
# @return {Object}
###
export getProfileData = (userId) ->
	check userId, String

	services = _.filter Services, (s) -> s.active userId

	res = {}
	for service in services
		data = getServiceProfileData service.name, userId
		if data.courseInfo?
			data.courseInfo.schoolVariant = normalizeSchoolVariant data.courseInfo.schoolVariant
		res[service.name] = data
	res
