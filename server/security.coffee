Meteor.startup -> # my eyes feel dizzy, i think. cant remember. please. help.
	BrowserPolicy.content.allowStyleOrigin 'fonts.googleapis.com'

	BrowserPolicy.content.allowFontOrigin 'themes.googleusercontent.com'
	BrowserPolicy.content.allowFontOrigin 'fonts.gstatic.com'

	BrowserPolicy.content.allowImageOrigin 'www.gravatar.com'
	BrowserPolicy.content.allowImageOrigin 'http://csi.gstatic.com/'
	BrowserPolicy.content.allowImageOrigin 'http://stats.g.doubleclick.net'
	BrowserPolicy.content.allowImageOrigin 'https://stats.g.doubleclick.net'
	BrowserPolicy.content.allowImageOrigin 'https://adelbert.magister.net/'
	BrowserPolicy.content.allowImageOrigin 'www.google-analytics.com'
	BrowserPolicy.content.allowImageOrigin 'http://cdn.jsdelivr.net/'
	BrowserPolicy.content.allowImageOrigin 'ssl.gstatic.com'

	BrowserPolicy.content.allowMediaOrigin 'www.ispeech.org'

	BrowserPolicy.content.allowScriptOrigin 'html5shiv.googlecode.com'
	BrowserPolicy.content.allowScriptOrigin 'rawgit.com'
	BrowserPolicy.content.allowScriptOrigin 'apis.google.com'
	BrowserPolicy.content.allowScriptOrigin 'www.google-analytics.com'
	BrowserPolicy.content.allowScriptOrigin 'www.google.com'
	BrowserPolicy.content.allowScriptOrigin 'www.gstatic.com'
	BrowserPolicy.content.allowScriptOrigin 'cdn.mathjax.org'

	BrowserPolicy.content.allowFrameOrigin 'accounts.google.com'
	BrowserPolicy.content.allowFrameOrigin 'docs.google.com'
	BrowserPolicy.content.allowFrameOrigin 'content.googleapis.com'
	BrowserPolicy.content.allowFrameOrigin 'www.google.com'

	BrowserPolicy.content.allowEval()

Meteor.users.allow
	update: (userId, doc, fields, modifier) ->
		allowed = [
			'classInfos'
			'externalServices'
			'mailSignup'
			'schedular'
			'privacyOptions'
			'profile'
			'hasGravatar'
			'studyGuidesHashes'
			'gradeNotificationDismissTime'
		]
		userId is doc._id and not _.any fields, (f) -> not _.contains allowed, f

Classes.allow
	insert: -> yes

Books.allow
	insert: -> yes

CalendarItems.allow
	insert: (userId, doc) -> doc.ownerId is userId
	update: (userId, doc, fields, modifier) -> userId in doc.userIds
	remove: (userId, doc) -> userId is doc.ownerId

Projects.allow
	insert: (userId, doc) -> doc.ownerId is userId and _.contains doc.participants, userId
	update: (userId, doc, fields, modifier) ->
		isParticiapnt = _.contains doc.participants, userId
		isOwner = userId is doc.ownerId

		modifiesAllowedFields = (
			leaves = EJSON.equals modifier, { $pull: participants: userId }
			leaves or not _.any ['ownerId', 'participants'], (x) -> _.contains fields, x
		)

		return isParticiapnt and ( modifiesAllowedFields or isOwner )
	remove: -> no

ChatMessages.allow
	insert: -> yes
	update: -> no # Not yet. We don't have have GUI to change it or to show it. (which is really important).
	remove: -> no # Never I guess.

GoaledSchedules.allow
	insert: -> yes
	update: (userId, doc) -> doc.ownerId is userId
	remove: -> no

Schools.allow
	insert: -> yes
	update: -> no # maybe later?
	remove: -> no

# StoredGrades and StudyUtils are only updated serverside.
StoredGrades.allow
	insert: -> no
	update: -> no
	remove: -> no

StudyUtils.allow
	insert: -> no
	update: -> no
	remove: -> no
