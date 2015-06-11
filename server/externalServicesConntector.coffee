GRADES_INVALIDATION_TIME = 1000 * 60 * 20 # 20 minutes

###*
# A static class that connects to and retrieves data from
# external services (eg. Magister).
#
# @class ExternalSercicesConnector
# @static
###
class @ExternalSercicesConnector
	@externalServices = []

	@pushExternalService: (module) =>
		###*
		# Gets or sets the info in the database.
		#
		# @method storedInfo
		# @param [userId] {String} The ID of the user to get (and modify) the data in the database of. If null the current Meteor.userId() will be used.
		# @param [obj] {Object} The object to replace the object stored in the database with.
		# @return {Object} The info stored in the database.
		###
		module.storedInfo = (userId, obj) ->
			check userId, Match.Optional String
			check obj, Match.Optional Object

			data = -> Meteor.users.findOne(userId).externalServices[module.name]
			userId ?= Meteor.userId()
			old = data() ? {}

			if obj?
				x = {}
				x["externalServices.#{module.name}"] = _.extend old, obj

				Meteor.users.update userId, $set: x

			data()

		###*
		# Checks if the user for the given `userId` has data for this module.
		# @method hasData
		# @param [userId] {String|User} The (ID of) the user to check. If null the current Meteor.userId() will be used.
		# @return {Boolean} Whether or not the given `user` has data for the current module.
		###
		module.hasData = (userId) ->
			check userId, Match.Optional Match.OneOf String, Object

			userId ?= Meteor.userId()
			userId = userId._id ? userId

			not _.isEmpty module.storedInfo(userId)

		@externalServices.push module

		###*
		# Set/Get active state for the current module for the user of the given `userId`.
		# @method active
		# @param [userId] {String|User} The (ID of) the user to check. If null the current Meteor.userId() will be used.
		# @param [val] {Boolean} The value to set the active state of this module to.
		# @return {Boolean} Whether or not the current module is active.
		###
		module.active = (userId, val) ->
			check userId, Match.Optional Match.OneOf String, Object
			check val, Match.Optional Boolean

			userId ?= Meteor.userId()
			userId = userId._id ? userId
			storedInfo = module.storedInfo userId

			if val?
				module.storedInfo userId, active: !!val

			module.hasData(userId) and (storedInfo.active ? yes)

Meteor.methods
	###*
	# Updates the grades in the database for the given `userId` or the user
	# in of current connection, unless the grades were updated shortly before.
	#
	# @method updateGrades
	# @param [userId=this.userId] {String} `userId` overwrites the `this.userId` which is used by default which is used by default.
	# @param [forceUpdate=false] {Boolean} If true the grades will be forced to update, otherwise the grades will only be updated if they weren't updated in the last 20 minutes.
	# @param [async=false] {Boolean} If true the execution of this method will allow other method invocations to run in a different fiber.
	# @return {Error[]} An array containing errors from ExternalServices.
	###
	'updateGrades': (userId, forceUpdate = no, async = no) ->
		@unblock() if async
		check userId, Match.Optional String

		userId ?= @userId
		user = Meteor.users.findOne userId
		errors = []

		return errors if not forceUpdate and user.lastGradeUpdateTime?.getTime() > _.now() - GRADES_INVALIDATION_TIME

		services = _.filter ExternalSercicesConnector.externalServices, (s) -> s.hasData userId
		for externalService in services
			result = null
			try
				result = externalService.getGrades userId,
					from: null
					to: null
					onlyRecent: no
					onlyEnds: no

			catch e
				console.log 'error while fetching grades from service.', e
				errors.push e

			for grade in result ? []
				# Update the grade if we're on the server and if it's changed.
				val = StoredGrades.findOne
					ownerId: userId
					externalId: grade.externalId

				if val? and Meteor.isServer
					delete grade._id
					unless EJSON.equals grade, val # Is this really necessary?
						StoredGrades.update val._id, grade
				else
					StoredGrades.insert grade

		Meteor.users.update(userId, $set: lastGradeUpdateTime: new Date) if services.length > 0
		errors

	###*
	# Gets the grades for the user with the given `userId` or the user in the
	# current connection from various sources. It also stores the retreived grades
	# in the database unless they were already in it.
	#
	# @method getGrades
	# @param [options] {Object} A map of options that is passed to the service.
	# @param [userId=this.userId] `userId` overwrites the `this.userId` which is used by default which is used by default.
	# @return {StoredGrade[]} The grades you asked for.
	###
	'getGrades': (options = {}, userId = @userId) ->
		@unblock()

		options = _.defaults options,
			from: new Date 0
			to: new Date
			onlyRecent: no
			onlyEnds: no

		Meteor.call 'updateGrades' unless @isSimulation

		StoredGrades.find(
			ownerId: userId
			dateFilledIn:
				$gte: (
					if options.onlyRecent
						new Date().addDays -7
					else
						options.from
				)
				$lte: options.to
			isEnd: options.onlyEnds
		).fetch()

	'getPersons': (query, userId) ->
		check query, String
		check userId, Match.Optional String

		query = query.toLowerCase()
		userId ?= @userId
		doneQueries = []

		services = _.filter @externalServices, (s) -> s.hasData userId
		for service in services
			service.getPersons
		undefined

	###*
	# Returns an array containg info about available services.
	# @method getModuleInfo
	# @param [userId=this.userId] {String} The ID of the user to use for the service info.
	# return {Object[]} An array containg objects that hold the info about all the services.
	###
	'getModuleInfo': (userId = @userId) ->
		check userId, String

		_.map ExternalSercicesConnector.externalServices, (s) ->
			name: s.name
			active: s.active userId
			hasData: s.hasData userId

	'createServiceData': (serviceDbName, params...) ->
		check serviceDbName, String

		service = _.find ExternalSercicesConnector.externalServices, (s) -> s.name is serviceDbName
		if service?
			service.createData params...
		else
			throw new Meteor.Error 'notfound', "No module with the name '#{serviceDbName}' found."
		undefined

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

# Lets push those bindings
ExternalSercicesConnector.pushExternalService MagisterBinding
