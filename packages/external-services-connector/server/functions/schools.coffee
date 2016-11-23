import { Services, ExternalServicesConnector } from '../connector.coffee'

export getServiceSchools = (serviceName, query, userId) ->
	check serviceName, String
	check query, String
	check userId, String

	service = _.find Services, (s) -> s.name is serviceName

	unless service?
		throw new Meteor.Error 'notFound', "No service with name '#{serviceName}' found"

	unless service.getSchools?
		throw new Meteor.Error 'incorrectRequest', "#{serviceName} doesn't have an `getSchools` method"

	try
		result = service.getSchools query
	catch e
		ExternalServicesConnector.handleServiceError service.name, userId, e
		throw new Meteor.Error 'externalError', "Error while retreiving schools from #{serviceName}"

	for school in result
		val = Schools.findOne "externalInfo.#{serviceName}.id": school.id

		unless val?
			s = new School school.name, school.genericUrl
			s.externalInfo[serviceName] =
				id: school.id
				url: school.url
			Schools.insert s

	Schools.find(
		"externalInfo.#{serviceName}": $exists: yes
		name: $regex: query, $options: 'i'
	).fetch()

export getSchools = (query, userId) ->
	check query, String
	check userId, String

	services = _.filter Services, (s) -> s.getSchools?
	for service in services
		getServiceSchools service.name, query, userId

	Schools.find(
		name: $regex: query, $options: 'i'
	).fetch()
