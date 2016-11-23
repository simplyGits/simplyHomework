import { ExternalServicesConnector, getServices } from '../connector.coffee'

###*
# Returns the personal classes from externalServices for the given `userId`
# @method getExternalPersonClasses
# @param userId {String} The ID of the user to get the classes from.
# @return {SchoolClass[]} The external classes as SchoolClasses
###
export getExternalPersonClasses = (userId) ->
	check userId, String

	courseInfo = getCourseInfo userId
	result = []

	unless courseInfo?
		throw new Meteor.Error 'unauthorized'

	{ year, schoolVariant } = courseInfo

	services = getServices userId, 'getPersonClasses'
	for service in services
		try
			classes = service.getPersonClasses(userId).filter (c) ->
				c.name.toLowerCase() not in [
					'gemiddelde'
					'tekortpunten'
					'toetsweek'
					'combinatiecijfer'
				] and c.abbreviation.toLowerCase() not in [
					'maestro'
					'scr'
				]
		catch e
			ExternalServicesConnector.handleServiceError service.name, userId, e
			continue

		result = result.concat classes.map (c) ->
			_class = Classes.findOne
				$or: [
					{ name: $regex: c.name, $options: 'i' }
					{ abbreviations: c.abbreviation.toLowerCase() }
				]
				schoolVariant: schoolVariant
				year: year

			unless _class?
				_class = new SchoolClass(
					c.name.toLowerCase(),
					c.abbreviation.toLowerCase(),
					year,
					schoolVariant
				)

				# Insert the class and set the id to the class object.
				# This is needed since the class object doesn't have an ID yet, but the
				# things further down the road requires it.
				_class._id = insertClass _.cloneDeep _class

			_class.externalInfo =
				id: c.id
				abbreviation: c.abbreviation
				name: c.name
				fetchedBy: service.name

			_class

	result
