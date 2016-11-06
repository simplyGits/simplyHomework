Meteor.startup -> # my eyes feel dizzy, i think. cant remember. please. help.
	BrowserPolicy.content.allowStyleOrigin 'fonts.googleapis.com'

	BrowserPolicy.content.allowFontOrigin 'themes.googleusercontent.com'
	BrowserPolicy.content.allowFontOrigin 'fonts.gstatic.com'

	BrowserPolicy.content.allowImageOrigin 'www.gravatar.com'
	BrowserPolicy.content.allowImageOrigin 'https://csi.gstatic.com/'
	BrowserPolicy.content.allowImageOrigin 'https://stats.g.doubleclick.net'
	BrowserPolicy.content.allowImageOrigin 'https://adelbert.magister.net/'
	BrowserPolicy.content.allowImageOrigin 'www.google-analytics.com'
	BrowserPolicy.content.allowImageOrigin 'https://www.google.com/'
	BrowserPolicy.content.allowImageOrigin 'https://www.google.nl/'
	BrowserPolicy.content.allowImageOrigin 'https://cdn.jsdelivr.net/'
	BrowserPolicy.content.allowImageOrigin 'ssl.gstatic.com'
	BrowserPolicy.content.allowImageOrigin 'apis.google.com'
	BrowserPolicy.content.allowImageOrigin 'latex.codecogs.com'

	BrowserPolicy.content.allowScriptOrigin 'html5shiv.googlecode.com'
	BrowserPolicy.content.allowScriptOrigin 'apis.google.com'
	BrowserPolicy.content.allowScriptOrigin 'www.google-analytics.com'
	BrowserPolicy.content.allowScriptOrigin 'www.google.com'
	BrowserPolicy.content.allowScriptOrigin 'www.gstatic.com'
	BrowserPolicy.content.allowScriptOrigin 'cdn.mathjax.org'
	BrowserPolicy.content.allowScriptOrigin 'https://ajax.cloudflare.com/'
	BrowserPolicy.content.allowScriptOrigin 'https://cdn.onesignal.com/'

	BrowserPolicy.content.allowFrameOrigin 'accounts.google.com'
	BrowserPolicy.content.allowFrameOrigin 'docs.google.com'
	BrowserPolicy.content.allowFrameOrigin 'content.googleapis.com'
	BrowserPolicy.content.allowFrameOrigin 'www.google.com'

	BrowserPolicy.content.allowEval()

Meteor.users.allow
	update: (userId, doc, fields, modifier) ->
		allowed = [
			'events'
			'settings'
			'profile'
			'setupProgress'
		]
		userId is doc._id and not _.any fields, (f) -> not _.contains allowed, f

Projects.allow
	insert: (userId, doc) -> no
	update: (userId, doc, fields, modifier) -> _.contains doc.participants, userId
	remove: -> no
