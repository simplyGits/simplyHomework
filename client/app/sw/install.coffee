Meteor.startup ->
	navigator.serviceWorker?.register(
		'/sw.js'
		{ scope: '/app/*' }
	).then ->
		console.log 'registered serviceworker'
	, ->
		console.log 'failed to register serviceworker'

	undefined
