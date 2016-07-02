import { Services, ExternalServicesConnector } from '../connector.coffee'

###*
# @method updateCourses
# @param {String} userId
# @return {Error[]}
###
export updateCourses = (userId) ->
	check userId, String
	errors = []

	services = _.filter Services, (s) -> s.updateCourse? and s.active userId
	for service in services
		try
			service.updateCourse userId
		catch e
			ExternalServicesConnector.handleServiceError service.name, userId, e
			errors.push e

	errors
