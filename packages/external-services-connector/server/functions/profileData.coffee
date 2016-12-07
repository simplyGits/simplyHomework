import { Services, ExternalServicesConnector } from '../connector.coffee'
import { trackPerformance } from './util.coffee'

export getServiceProfileData = (serviceName, userId) ->
	check serviceName, String
	check userId, String

	service = _.find Services, name: serviceName

	unless service?
		throw new Meteor.Error 'service-not-found', "No service with name '#{serviceName}' found"
	unless service.getProfileData?
		return undefined

	try
		done = trackPerformance serviceName, 'getProfileData', [ userId ]
		data = service.getProfileData userId
		done()

		if data.courseInfo?.schoolVariant?
			data.courseInfo.schoolVariant =
				normalizeSchoolVariant data.courseInfo.schoolVariant

		data
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

	_(services)
		.pluck 'name'
		.map (name) -> [ name, getServiceProfileData(name, userId) ]
		.object()
		.value()
