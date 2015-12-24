ExternalServiceErrors = new Meteor.Collection 'externalServiceErrors'

###*
# A static class that connects to and retrieves data from
# external services (eg. Magister).
#
# @class ExternalServicesConnector
# @static
###
class ExternalServicesConnector
	@externalServices: []
	@handleServiceError: (serviceName, userId, error) ->
		ExternalServiceErrors.insert
			service: serviceName
			userId: userId
			date: new Date
			error: error

	@pushExternalService: (module) =>
		###*
		# Gets or sets the info in the database.
		#
		# @method storedInfo
		# @param [userId=Meteor.userId()] {String} The ID of the user to get (and modify) the data in the database of. If null the current Meteor.userId() will be used.
		# @param [obj] {Object|null} The object to replace the object stored in the database with. If `null` the currently stored info will be _removed_.
		# @return {Object} The info stored in the database.
		###
		module.storedInfo = (userId = Meteor.userId(), obj) ->
			check userId, Match.Optional String
			check obj, Match.Optional Match.OneOf Object, null

			data = ->
				Meteor.users.findOne(
					userId
					fields: externalServices: 1
				).externalServices[module.name]
			old = data() ? {}

			if obj?
				Meteor.users.update userId,
					$set: "externalServices.#{module.name}": _.extend old, obj

			else if _.isNull obj
				Meteor.users.update userId,
					$unset: "externalServices.#{module.name}": yes

			data()

		###*
		# Checks if the user for the given `userId` has data for this module.
		# @method hasData
		# @param [userId] {String} The ID of the user to check. If `undefined` the current this.userId will be used.
		# @return {Boolean} Whether or not the given `user` has data for the current module.
		###
		module.hasData = (userId = @userId) ->
			check userId, Match.Optional Match.OneOf String, Object
			not _.isEmpty module.storedInfo(userId)

		###*
		# Set/Get active state for the current module for the user of the given `userId`.
		# @method active
		# @param [userId] {String} The ID of the user to check. If null the current this.userId will be used.
		# @param [val] {Boolean} The value to set the active state of this module to.
		# @return {Boolean} Whether or not the current module is active.
		###
		module.active = (userId = @userId, val) ->
			check userId, Match.Optional Match.OneOf String, Object
			check val, Match.Optional Boolean

			storedInfo = module.storedInfo userId

			if val?
				module.storedInfo userId, active: !!val

			module.hasData(userId) and (storedInfo?.active ? yes)

		###
		CalendarItems.find(
			fetchedBy: module.name
		).observe
			changed: module.calendarItemChanged
		###

		@externalServices.push module

# Just a shortcut.
Services = ExternalServicesConnector.externalServices

@Services = Services
@ExternalServicesConnector = ExternalServicesConnector

#Meteor.publish "externalPersons", (query) ->
#	#var words = query.toLowerCase().split(" ");
#	#var persons = _.filter(allPersons, function (p) {
#	#	return _.any(words, function (word) {
#	#		return p.firstName.toLowerCase().indexOf(word) > -1 || p.lastName.toLowerCase().indexOf(word) > -1;
#	#	});
#	#});
#
#	words = query.toLowerCase().split " "
#	persons = Meteor.users.find(
#		"profile.firstName": 
#	).fetch()
#
#	services = _.filter @externalServices, (s) -> s.hasData user
#	
#	for service.getPersons
