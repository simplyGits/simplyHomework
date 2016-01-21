types = [{
	type: 'vocab'
	keywords: [
		'woordenlijst'
		'woordlijst'
		'woorden'
		'vocab'
	]
}, {
	type: 'report'
	keywords: [
		'samenvatting'
	]
}].map (t) -> _.extend t,
	regex: (
		keywords = t.keywords.map((w) -> "#{w}(en|s)?").join '|'
		new RegExp "\\b(#{keywords})\\b"
	)

filterKeywords = (query) ->
	keywords = _(types)
		.filter (type) ->
			match = type.regex.exec query
			if match?
				query = query.replace match[0], ''
				yes
			else no
		.pluck 'type'
		.value()
	[keywords, query]

filterClasses = (query, userId) ->
	querySplitted = query.split ' '
	res = []
	if querySplitted.length >= 1
		{ year, schoolVariant } = getCourseInfo userId
		classIds = _.pluck getClassInfos(userId), 'id'

		for word in querySplitted
			c = Classes.findOne
				_id: $in: classIds
				$or: [
					{ name: $regex: word, $options: 'i' }
					{ abbreviations: word.toLowerCase() }
				]
				schoolVariant: schoolVariant
				year: year

			if c?
				res.push c._id
				query = query.replace word, ''

	[res, query]

###*
# @class Search
# @static
###
class Search
	@_providers: []
	###*
	# @method provide
	# @param {String} name
	# @param {Function} fn
	###
	@provide: ->
		name = _.find arguments, (a) -> _.isString a
		fn = _.find arguments, (a) -> _.isFunction a

		check name, String
		check fn, Function

		if _.find(@_providers, { name })?
			throw new Error "Provider '#{name}' already inserted."

		@_providers.push { name, fn }
		undefined

	# TODO: Allow for smart searching, instead of just keyword searching it could
	# use natural language processing to find specefic stuff.

	###*
	# @method search
	# @param {string} userId
	# @param {Object} options
	# 	@param {String} options.query
	# 	@param {String[]} [options.classIds]
	# 	@param {String[]} [options.onlyFrom]
	# 	@param {String[]} [options.defaultKeywords]
	# @return {Object[]}
	###
	@search: (userId, options) ->
		check userId, String
		check options, Object
		check options.query, String
		check options.classIds, Match.Optional [String]
		check options.onlyFrom, Match.Optional [String]
		check options.defaultKeywords, Match.Optional [String]

		query = originalQuery = options.query.trim().toLowerCase()
		options.classIds ?= []
		options.onlyFrom ?= []

		return [] if query.length is 0

		if options.classIds.length is 0
			[classIds, query] = filterClasses query, userId
		else
			classIds = options.classIds
		classes = classIds.map (id) -> Classes.findOne _id: id

		[keywords, query] = filterKeywords query
		if _.isEmpty(keywords) and _.isArray(options.defaultKeywords)
			keywords = options.defaultKeywords

		query = query.trim()
		providers = _.filter @_providers, (p) ->
			options.onlyFrom.length is 0 or p.name in options.onlyFrom

		user = Meteor.users.findOne userId
		dam = DamerauLevenshtein insert: 0
		calcDistance = (s) -> dam query, s.trim().toLowerCase()
		res = []
		for provider in providers
			try
				out = provider.fn
					user: user
					query: query
					rawQuery: originalQuery
					classIds: options.classIds
					classes: classes
					keywords: keywords
				res = res.concat out if _.isArray out
			catch e
				console.warn "Search provider '#{provider.name}' errored.", e
				Kadira.trackError 'search-provider-failure', e.toString(), stacks: JSON.stringify e

		query = if query.length > 0 then query else originalQuery
		_(res)
			.filter (obj) ->
				obj.filtered or
				calcDistance(obj.title) < 3 or
				Helpers.contains obj.title, query, yes

			.sortByAll [
				(obj) ->
					titleLower = obj.title.toLowerCase()
					dam = DamerauLevenshtein
						insert: .5
						remove: 2

					distance = _(titleLower)
						.split ' '
						.map (word) -> dam query, word
						.min()

					amount = 0
					# If the name contains a word beginning with the query; lower distance
					# a substensional amount.
					splitted = titleLower.split ' '
					index = _.findIndex splitted, (s) -> s.indexOf(query) > -1
					if index isnt -1
						amount += query.length + (splitted.length - index) * 5

					distance - amount
				'title'
			]

			# amount that is visibile on client is limited to 7, we don't want to send
			# unnecessary data to the client:
			.take 7
			.value()

@Search = Search
