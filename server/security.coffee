Meteor.startup -> # my eyes feel dizzy, i think. cant remember. please. help.
	BrowserPolicy.content.allowStyleOrigin "maxcdn.bootstrapcdn.com"
	BrowserPolicy.content.allowStyleOrigin "fonts.googleapis.com"

	BrowserPolicy.content.allowFontOrigin "themes.googleusercontent.com"
	BrowserPolicy.content.allowFontOrigin "fonts.gstatic.com"
	BrowserPolicy.content.allowFontOrigin "maxcdn.bootstrapcdn.com"

	BrowserPolicy.content.allowImageOrigin "www.gravatar.com"
	BrowserPolicy.content.allowImageOrigin "http://csi.gstatic.com/"
	BrowserPolicy.content.allowImageOrigin "http://stats.g.doubleclick.net"
	BrowserPolicy.content.allowImageOrigin "https://adelbert.magister.net/"
	BrowserPolicy.content.allowImageOrigin "www.google-analytics.com"

	BrowserPolicy.content.allowMediaOrigin "www.ispeech.org"

	BrowserPolicy.content.allowScriptOrigin "html5shiv.googlecode.com"
	BrowserPolicy.content.allowScriptOrigin "rawgit.com"
	BrowserPolicy.content.allowScriptOrigin "apis.google.com"
	BrowserPolicy.content.allowScriptOrigin "www.google-analytics.com"

	BrowserPolicy.content.allowFrameOrigin "accounts.google.com"
	BrowserPolicy.content.allowFrameOrigin "content.googleapis.com"
	
	BrowserPolicy.content.allowEval()

Meteor.users.allow
	update: (userId, doc, fields, modifier) ->
		allowed = [
			"classInfos"
			"mailSignup"
			"schedular"
			"profile"
			"hasGravatar"
			"studyGuidesHashes"
		]
		userId is doc._id and not _.any fields, (f) -> not _.contains allowed, f

Classes.allow
	insert: -> yes
	update: (userId, doc, fields, modifier) -> fields.length is 1 and fields[0] is "books"

Projects.allow
	insert: -> yes
	update: (userId, doc, fields, modifier) -> _.contains(doc.participants, userId) and ( !_.any(["creatorId", "participants"], (x) -> _.contains(fields, x)) or userId is doc.creatorId )
	remove: -> no