import { Services, ExternalServicesConnector } from '../connector.coffee'

###*
# @method updateCourses
# @param {String} userId
###
export updateCourses = (userId) ->
	check userId, String

	services = _.filter Services, (s) -> s.updateCourse? and s.active userId
	for serivce in services
		try
			service.updateCourse userId
		catch e
			ExternalServicesConnector.handleServiceError service.name, userId, e
