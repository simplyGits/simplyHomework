Meteor.startup -> # my eyes feel dizzy, i think. cant remember. please. help.
	BrowserPolicy.content.allowStyleOrigin "fonts.googleapis.com"
	BrowserPolicy.content.allowFontOrigin "themes.googleusercontent.com"
	BrowserPolicy.content.allowFontOrigin "fonts.gstatic.com"
	BrowserPolicy.content.allowFontOrigin "maxcdn.bootstrapcdn.com"
	BrowserPolicy.content.allowStyleOrigin "maxcdn.bootstrapcdn.com"
	BrowserPolicy.content.allowImageOrigin "www.gravatar.com"
	BrowserPolicy.content.allowImageOrigin "http://csi.gstatic.com/"
	BrowserPolicy.content.allowImageOrigin "https://adelbert.magister.net/"
	BrowserPolicy.content.allowMediaOrigin "www.ispeech.org"
	BrowserPolicy.content.allowScriptOrigin "html5shiv.googlecode.com"
	BrowserPolicy.content.allowScriptOrigin "rawgit.com"
	BrowserPolicy.content.allowScriptOrigin "apis.google.com"
	BrowserPolicy.content.allowScriptOrigin "www.google-analytics.com"
	BrowserPolicy.content.allowImageOrigin "www.google-analytics.com"
	BrowserPolicy.content.allowFrameOrigin "accounts.google.com"
	BrowserPolicy.content.allowFrameOrigin "content.googleapis.com"
	BrowserPolicy.content.allowEval()

Meteor.users.allow
	update: (userId, doc, fields, modifier) -> userId is doc._id and (_.contains(fields, "profile") or _.contains(fields, "classInfos") or _.contains(fields, "mailSignup") or _.contains(fields, "schedular"))

Projects.allow
	insert: -> yes
	update: (userId, doc, fields, modifier) -> _.contains(doc._participants, userId) and ( !_.contains(fields, "_creatorId") or userId is doc._creatorId )
	remove: -> no

BetaPeople.allow
	insert: -> yes
	update: -> no
	remove: -> no