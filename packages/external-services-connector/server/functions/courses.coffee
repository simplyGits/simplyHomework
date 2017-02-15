import { Services, ExternalServicesConnector } from '../connector.coffee'

###*
# @method getCourses
# @param {String} userId
# @return {Course[]}
###
export getCourses = (userId) ->
	check userId, String
	res = []

	services = _.filter Services, (s) -> s.getCourses? and s.active userId
	for service in services
		try
			res = res.concat service.getCourses userId
		catch e
			ExternalServicesConnector.handleServiceError service.name, userId, e

	res
