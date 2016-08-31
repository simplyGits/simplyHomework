ExternalServiceErrors = new Mongo.Collection 'externalServiceErrors'
{ AuthError } = require '../lib/errors.coffee'

###*
# A static class that connects to and retrieves data from
# external services (eg. Magister).
#
# @class ExternalServicesConnector
# @static
###
class ExternalServicesConnector
	@services: []
	@handleServiceError: (serviceName, userId, error) ->
		return if error instanceof AuthError
		console.log "error while running '#{arguments.callee.caller.name}' for service '#{serviceName}'", error
		ExternalServiceErrors.insert
			service: serviceName
			userId: userId
			date: new Date
			message: error.message ? error.toString()
			stack: error.stack

	###*
	# @method getServices
	# @param {String} userId
	# @param {String} thing
	# @return {Service[]}
	###
	@getServices: (userId, thing) =>
		_.filter @services, (s) -> s.can userId, thing

	@pushExternalService: (service) =>
		###*
		# Gets or sets the info in the database.
		#
		# @method storedInfo
		# @param userId {String} The ID of the user to get (and modify) the data in the database of. If null the current Meteor.userId() will be used.
		# @param [obj] {Object|null} The object to replace the object stored in the database with. If `null` the currently stored info will be _removed_.
		# @return {Object} The info stored in the database.
		###
		service.storedInfo = (userId, obj) ->
			check userId, String
			check obj, Match.Optional Match.OneOf Object, null

			data = ->
				Meteor.users.findOne(
					userId
					fields: "externalServices.#{service.name}": 1
				).externalServices[service.name]

			if _.isPlainObject obj
				Meteor.users.update userId,
					$set: "externalServices.#{service.name}": _.extend data() ? {}, obj

			else if _.isNull obj
				Meteor.users.update userId,
					$unset: "externalServices.#{service.name}": yes

			data()

		###*
		# Checks if the user for the given `userId` has data for this service.
		# @method hasData
		# @param [userId] {String} The ID of the user to check. If `undefined` the current this.userId will be used.
		# @return {Boolean} Whether or not the given `user` has data for the current service.
		###
		service.hasData = (userId = @userId) ->
			check userId, Match.Optional Match.OneOf String, Object
			not _.isEmpty service.storedInfo(userId)

		###*
		# Set/Get active state for the current service for the user of the given `userId`.
		# @method active
		# @param [userId] {String} The ID of the user to check. If null the current this.userId will be used.
		# @param [val] {Boolean} The value to set the active state of this service to.
		# @return {Boolean} Whether or not the current service is active.
		###
		service.active = (userId = @userId, val) ->
			check userId, Match.Optional Match.OneOf String, Object
			check val, Match.Optional Boolean

			if val?
				service.storedInfo userId, active: val

			service.hasData(userId) and (service.storedInfo(userId)?.active ? yes)

		###*
		# @method can
		# @param {String} userId
		# @param {String} thing
		# @return {Boolean}
		###
		service.can ?= (userId, thing) ->
			service.active(userId) and _.isFunction service[thing]

		###*
		# @method log
		# @param {...String} strings
		###
		service.log = (strings...) ->
			console.log '[' + service.name + ']', strings...
			undefined

		@services.push service

exports.ExternalServicesConnector = ExternalServicesConnector

# shortcuts
exports.Services = ExternalServicesConnector.services
exports.getServices = ExternalServicesConnector.getServices

exports.functions = require './functions.coffee'
_.extend exports, require '../lib/errors.coffee'

require './methods.coffee'
require './publish.coffee'
require './router.coffee'
