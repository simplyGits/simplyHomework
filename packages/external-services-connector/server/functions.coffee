{ Services, ExternalServicesConnector, getServices } = require './connector.coffee'

###*
# Gets the assignments for the user with the given `userId`.
# @method getExternalAssignments
# @param userId {String} The ID of the user to get the assignments for.
# @return {Assignment[]}
###
getExternalAssignments = (userId) ->
	check userId, String

	user = Meteor.users.findOne userId
	result = []

	unless user?
		throw new Meteor.Error 'unauthorized'

	services = getServices userId, 'getAssignments'
	for service in services
		assignments = service.getAssignments userId
		result = result.concat assignments

	result

###*
# Returns an array containing info about available services.
# @method getModuleInfo
# @param userId {String} The ID of the user to use for the service info.
# @return {Object[]} An array containing objects that hold the info about all the services.
###
getModuleInfo = (userId) ->
	check userId, String

	_.map Services, (s) ->
		name: s.name
		friendlyName: s.friendlyName
		active: s.active userId
		hasData: s.hasData userId
		loginNeeded: s.loginNeeded

exports.getExternalAssignments = getExternalAssignments
exports.getModuleInfo = getModuleInfo

# wat.
export * from './functions/calendarItems.coffee'
export * from './functions/classes.coffee'
export * from './functions/grades.coffee'
export * from './functions/persons.coffee'
export * from './functions/schools.coffee'
export * from './functions/studyUtils.coffee'
export * from './functions/messages.coffee'
export * from './functions/profileData.coffee'
export * from './functions/serviceUpdates.coffee'
