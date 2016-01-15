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
		new RegExp "\b(#{keywords})\b"
	)

filterKeywords = (query) ->
	_(types)
		.filter (type) -> type.regex.test query
		.pluck 'type'
		.value()

###*
# @class Search
# @static
###
class Search
	@_providers: []
	###*
	# @method provide
	# @param {String} name
	# @param {String[]} [handles]
	# @param {Function} fn
	###
	@provide: (name, fn) ->
		name = _.find arguments, (a) -> _.isString a
		handles = _.find arguments, (a) -> _.isArray a
		fn = _.find arguments, (a) -> _.isFunction a

		check name, String
		check handles, Match.Optional [String]
		check fn, Function

		if _.find(@_providers, { name })?
			throw new Error "Provider '#{name}' already inserted."

		@_providers.push { name, handles, fn }
		undefined

	# TODO: Allow for smart searching, instead of just keyword searching it could
	# use natural language processing to find specefic stuff.

	###*
	# @method search
	# @param {string} userId
	# @param {Object} options
	# 	@param {String} options.query
	# 	@param {String[]} [options.classIds]
	# @return {Object[]}
	###
	@search: (userId, options) ->
		check userId, String
		check options, Object
		check options.query, String
		check options.classIds, Match.Optional [String]

		query = options.query.trim().toLowerCase()
		###
		orig = query.trim().toLowerCase()
		query = orig.replace /(woordenlijst(en))/g, ''
		###

		return [] if query.length is 0

		dam = DamerauLevenshtein insert: 0
		calcDistance = (s) -> dam query, s.trim().toLowerCase()
		user = Meteor.users.findOne userId

		keywords = filterKeywords query
		providers = (
			if keywords.length is 0 then @_providers
			else _.filter @_providers, (p) ->
				_.any keywords, (keyword) -> keyword in p.handles
		)

		res = []
		for provider in providers
			try
				out = provider.fn
					user: user
					query: query
					classIds: options.classIds ? []
				res = res.concat out if _.isArray out
			catch e
				console.warn "Search provider '#{provider.name}' errored.", e
				Kadira.trackError 'search-provider-failure', e.toString(), stacks: JSON.stringify e

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
