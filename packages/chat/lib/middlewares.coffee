###*
# @class ChatMiddlewares
# @static
###
@ChatMiddlewares =
	_middlewares: []
	###*
	# Attaches a middleware. Order sensetive.
	#
	# @method attach
	# @param {String} name
	# @param {String} platform
	# @param {String} fn
	###
	attach: (name, platform, fn) ->
		check name, String
		check platform, String
		check fn, Function

		item = { name, platform, fn }

		@_middlewares.push item

	###*
	# Runs the given `message` through every middleware in order.
	# @method run
	# @param {ChatMessage} message
	# @param {String} [platform] The platform to run the middlewares for, if none is given one will automatically be chosen.
	# @return {ChatMessage}
	###
	run: (message, platform) ->
		platform ?= if Meteor.isClient then 'client' else 'server'

		for item in @_middlewares when item.platform is platform
			try
				message = item.fn message
			catch e
				console.warn "Message middleware '#{item.name}' errored.", e
				Kadira.trackError 'middleware-failure', e.toString(), stacks: JSON.stringify e

		message

ChatMiddlewares.attach 'create compiledContent field', 'server', (message) ->
	message.compiledContent = message.content
	message
