Meteor.startup ->
	navigator.serviceWorker?.register('/sw.js').catch (e) ->
		Kadira.trackError 'service-worker', e.message, stacks: e.stack
		console.error 'failed to register serviceworker', e

	undefined
