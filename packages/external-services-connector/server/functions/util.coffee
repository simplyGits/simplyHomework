import WaitGroup from 'meteor/simply:waitgroup'
ExternalServicePerformance = new Mongo.Collection 'externalServicePerformance'

###*
# @method handleCollErr
# @param {Error} e
###
export handleCollErr = (e) ->
	if e?
		Kadira.trackError(
			'external-services-connector'
			e.message
			{ stacks: e.stack }
		)

###*
# @method clone
# @param {Object} obj
# @return {Object}
###
export clone = (obj) -> EJSON.parse EJSON.stringify obj
###*
# Recursively omits the given keys from the given array or object.
# If `obj` isn't an array or object, this function will just return `obj`.
# @method omit
# @param {any} obj
# @param {String[]} keys
# @return {Object}
###
export omit = (obj, keys) ->
	if _.isArray obj
		_.map obj, (x) -> omit x, keys
	else if _.isPlainObject obj
		for key in keys
			obj = _.omit obj, key

		for key of obj
			if obj[key] is null
				delete obj[key]
			else
				obj[key] = omit obj[key], keys

		obj
	else
		obj

###*
# @method hasChanged
# @param {Object} a
# @param {Object} b
# @param {String[]} omitExtra
# @return {Boolean}
###
export hasChanged = (a, b, omitExtra = []) ->
	omitKeys = [ '_id' ].concat omitExtra

	not EJSON.equals(
		omit clone(a), omitKeys
		omit clone(b), omitKeys
	)

###*
# @method diffObjects
# @param {Object} a
# @param {Object} b
# @param {String[]} [exclude=[]]
# @param {Boolean} [ignoreCasing=true]
# @return {Object[]}
###
export diffObjects = (a, b, exclude = [], ignoreCasing = yes) ->
	a = clone(a)
	b = clone(b)
	omitKeys = [ '_id' ].concat exclude

	_(_.keys a)
		.concat _.keys b
		.uniq()
		.reject (x) -> x in omitKeys
		.map (key) ->
			key: key
			prev: a[key]
			next: b[key]
		.reject (obj) ->
			EJSON.equals(obj.prev, obj.next) or
			(
				ignoreCasing and
				_.isString(obj.prev) and _.isString(obj.next) and
				obj.prev.trim().toLowerCase() is obj.next.trim().toLowerCase()
			)
		.value()

###*
# @method markUserEvent
# @param {String} userId
# @param {String} name
###
export markUserEvent = (userId, name) ->
	check userId, String
	check name, String
	Meteor.users.update userId, $set: "events.#{name}": new Date

###*
# @method checkAndMarkUserEvent
# @param {String} userId
# @param {String} name
# @param {Number} invalidationTime
# @param {Boolean} [force=false]
# @return {Boolean}
###
export checkAndMarkUserEvent = (userId, name, invalidationTime, force = no) ->
	check userId, String
	check name, String
	check invalidationTime, Number
	check force, Boolean

	updateTime = getEvent name, userId
	if not force and updateTime? and updateTime > _.now() - invalidationTime
		no
	else
		markUserEvent userId, name
		yes

###*
# @method diffAndInsertFiles
# @param {String} userId
# @param {ExternalFile[]} files
# @return {Object}
###
export diffAndInsertFiles = (userId, files) ->
	vals = Files.find(
		externalId: $in: _.pluck files, 'externalId'
	).fetch()

	res = {}

	for file in files
		val = _.find vals,
			externalId: file.externalId

		id = file._id
		if val?
			ExternalFile.schema.clean file
			id = val._id

			# use the version with the newest creationDate
			if ((not file.creationDate or not file.creationDate) or file.creationDate > val.creationDate) and
			hasChanged val, file, [ 'downloadInfo', 'size' ]
				delete file._id
				Files.update val._id, { $set: file }, handleCollErr
		else
			id = Files.insert file, handleCollErr

		res[file._id] = id if file._id?

	res

trackPerformance = (sname, fname, params) ->
	a = process.hrtime()
	->
		diff = process.hrtime a
		ExternalServicePerformance.insert {
			service: sname
			fn: fname
			date: new Date
			params: params
			ns: diff[0]*1e9 + diff[1]
		}, handleCollErr

export fetchConcurrently = (services, fname, params...) ->
	results = {}
	group = new WaitGroup

	services.forEach (service) ->
		group.defer ->
			done = trackPerformance service.name, fname, params
			try
				results[service.name] = result: service[fname] params...
			catch error
				results[service.name] = { error }
			done()

	group.wait()
	results
