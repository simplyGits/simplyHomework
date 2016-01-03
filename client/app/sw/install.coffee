Meteor.startup ->
	navigator.serviceWorker?.register(
		'/sw.js'
		{ scope: '/app/*' }
	).catch (e) ->
		Kadira.trackError 'service-worker', e.message, stacks: e.stack
		console.error 'failed to register serviceworker', e

	undefined
