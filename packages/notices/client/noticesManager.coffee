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
			sort: priority: -1
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
							handle = Meteor.subscribe.apply this, arguments
							handles.push handle
							handle

					if res
						NoticeManager.notices.upsert {
							name: provider.name
						}, _.extend res,
							name: provider.name
							ready: undefined
					else
						NoticeManager.notices.remove name: provider.name
				catch e
					console.warn "Notice provider '#{provider.name}' errored.", e
					Kadira.trackError 'notice-provider-failure', e.toString(), stacks: JSON.stringify e

		Tracker.autorun ->
			if _.every(handles, (handle) -> handle.ready())
				ready.set yes

		ready: -> ready.get()

@NoticeManager = NoticeManager
