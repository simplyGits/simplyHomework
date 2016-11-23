import { getServices } from '../connector.coffee'

personCache = []
###*
# Gets the persons matching the given `query` and `type` for the
# user with the given `userId`
#
# @method getPersons
# @param query {String}
# @param [type] {String} one of: 'teacher', 'pupil' or `undefined` to find all.
# @param userId {String}
# @return {ExternalPerson[]}
###
export getPersons = (query, type = undefined, userId) ->
	check query, String
	check type, Match.Optional String
	check userId, String

	if type? and type not in [ 'teacher', 'pupil' ]
		throw new Meteor.Error 'invalid-type'

	result = []
	query = query.toLowerCase()
	types = (
		if type? then [ type ]
		else [ 'teacher', 'pupil' ]
	)

	# filter cache items from the cache based on userId, query and type.
	cached = _.filter personCache, (c) ->
		c.userId is userId and
		query.indexOf(c.query) is 0 and
		c.type in types

	# more cache filtering
	for c in cached
		if _.now() - c?.time > PERSON_CACHE_INVALIDATION_TIME
			# cache invalidated, remove item from the cache and continue.
			_.pull personCache, c
			continue

		# cache item is usable, pull the type since we have handled it and add the
		# results of the cache to the return array.
		_.pull types, c.type
		result = result.concat c.items

	# fetch items if still needed.
	if types.length > 0
		services = getServices userId, 'getPersons'

		# we don't want to store the items in result yet, because we only want to
		# create new cache items for the newely fetched items and the `result` array
		# already possibly contains items from the cache.
		fetched = []
		for service in services
			fetched = fetched.concat service.getPersons(userId, query, types)

		# cache newely fetched items by type.
		for type in types
			items = _.filter fetched, { type }
			personCache.push
				query: query
				userId: userId
				type: type
				items: _.filter fetched, { type }
				time: _.now()

		result = result.concat fetched

	result
