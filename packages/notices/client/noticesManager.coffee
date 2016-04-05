subs = new SubsManager
	expireIn: 60
	cacheLimit: 50

###*
# @class NoticeManager
# @static
###
class NoticeManager
	@notices: new Mongo.Collection null
	###*
	# Gets a cursor that points to all the notices, in decreasing priority.
	# @method get
	# @param {mixed} [query={}]
	# @return {Cursor}
	###
	@get: (query = {}) ->
		@notices.find query,
			sort:
				priority: -1
				name: 1
			transform: (n) -> _.extend n,
				clickable: if n.onClick? then 'clickable' else ''

	@_providers: []

	###*
	# @method provide
	# @param {String} name
	# @param {Function} fn See README.md for more info.
	###
	@provide: (name, fn) ->
		if _.find(@_providers, { name })?
			throw new Error "Provider '#{name}' already inserted."

		@_providers.push { name, fn }
		undefined

	###*
	# Fires up all the providers. If the current computation get's stopped it will
	# make sure to greacefully stop all the providers too.
	# Returns true if all providers are fired up and ready to go.
	#
	# @method run
	# @return {Boolean}
	###
	@run: ->
		# REVIEW: Should we clear the `notices` collection after the current
		# computation is stopped?

		# REVIEW: Should we register if there already is an running computation and
		# let only one be runnable at the same time?

		ready = new ReactiveVar no
		handles = []
		for provider in @_providers
			Tracker.autorun do (provider) -> ->
				try
					res = provider.fn.apply
						subscribe: ->
							handle = subs.subscribe arguments...
							handles.push handle
							handle
					unless _.isArray res
						res = if res then [ res ] else []

					if res.length is 0
						NoticeManager.notices.remove name: provider.name
					else for item in res
						id = item.id ? provider.name
						NoticeManager.notices.upsert id,
							_.extend item,
								_id: id
								name: provider.name
								ready: undefined

				catch e
					console.warn "Notice provider '#{provider.name}' errored.", e
					Kadira.trackError 'notice-provider-failure', e.toString(), stacks: JSON.stringify e

		Tracker.autorun ->
			if _.every(handles, (handle) -> handle.ready())
				ready.set yes

		ready: -> ready.get()

@NoticeManager = NoticeManager
