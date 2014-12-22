@ExecutedCommands = new Meteor.Collection "exectuedCommands"

Meteor.startup ->
	Accounts.urls.verifyEmail = (token) -> Meteor.absoluteUrl "verify/#{token}"
	Accounts.urls.resetPassword = (token) -> Meteor.absoluteUrl "reset/#{token}"

	Accounts.emailTemplates.siteName = "simplyHomework.nl"
	Accounts.emailTemplates.from = "simplyHomework <hello@simplyApps.nl>"

	Accounts.emailTemplates.resetPassword.subject = (user) -> "simplyHomework | Wachtwoord"
	Accounts.emailTemplates.resetPassword.html = (user, url) ->
		message = "Hey #{user.profile.firstName}!\n\n" +

		"Je was je wachtwoord vergeten, hier krijg je een nieuwe:\n" +
		'<a href="' + url + '">' + url + '</a>'

		return getMail message

	Accounts.emailTemplates.verifyEmail.subject = (user) -> "simplyHomework | Nieuw Account"
	Accounts.emailTemplates.verifyEmail.html = (user, url) ->
		message = "Hey #{user.profile.firstName}!\n\n" +

		"Welkom bij simplyHomework! Klik, om je account te verifieren, op deze link:\n" +
		'<a href="' + url + '">' + url + '</a>'

		return getMail message

	Meteor.users.find().observe
		changed: (old, newDoc) ->
			passChanged = old.services.password.bcrypt isnt newDoc.services.password.bcrypt
			mailChanged = old.emails[0].address isnt newDoc.emails[0].address

			if passChanged or mailChanged
				user = if mailChanged then old else newDoc
				message = "Hey #{user.profile.firstName}!\n\n" +
				(
					if passChanged and mailChanged then "Zojuist is het wachtwoord en het email adres van je account veranderd.\n"
					else if passChanged and not mailChanged then "Zojuist is het wachtwoord van je account veranderd.\n"
					else if not passChanged and mailChanged then "Zojuist is het mail adres van je account veranderd.\n"
				) +
				"Als je dit zelf was kan je dit bericht negeren en het uitprinten en als papieren vliegtuigje gebruiken ofzo.\n" +
				"Als je dit niet was heb je 2 opties:\n"+
				"- Rondjes rennen.\n" +
				"- Emailtje terug sturen (<a href=\"mailto:hello@simplyApps.nl\">hello@simplyApps.nl</a>)"
				
				subject = (
					if passChanged and mailChanged then "Wachtwoord en Mail Adres Veranderd"
					else if passChanged and not mailChanged then "Wachtwoord Veranderd"
					else if not passChanged and mailChanged then "Mail Adres Veranderd"
				)

				sendMail user, "simplyHomework | #{subject}", message

			unless EJSON.equals old.classInfos, newDoc.classInfos
				Projects.update { participants: newDoc._id, classId: $nin: (x.id for x in old.classInfos) }, { $pull: participants: newDoc._id }, multi: yes

	Projects.find().observe
		changed: (oldDoc, newDoc) ->
			if newDoc.participants.length is 0
				Projects.remove newDoc._id
			else if not _.contains(newDoc.participants, newDoc.ownerId)
				Projects.ownerId = newDoc.participants[0]

	recents = {}
	longTimeIgnore = []
	Accounts.onLoginFailure (res) ->
		{user, error} = res
		return unless error.error is 403 and user?
		if ++recents[user._id]?.times is 5
			message = "Hey,\n\n" +

			"Pas heeft iemand in een korte tijd meerdere keren een fout wachtwoord ingevuld.\n" +
			"Als jij dit niet was verander dan zo snel mogelijk je wachtwoord in <a href=\"#{Meteor.absoluteUrl()}\">simplyHomework</a>.\n" +
			"Als jij dit wel was en je bent je wachtwoord vergeten kan je het <a href=\"#{Meteor.absoluteUrl()}forgot\">hier</a> veranderen."

			sendMail user, "simplyHomework | Account mogelijk in gevaar", message

			delete recents[user._id]
			longTimeIgnore.push user._id
			Meteor.setTimeout (-> delete longTimeIgnore[user._id] ), 86400000

		else unless recents[user._id]? and not _.contains longTimeIgnore, user._id
			recents[user._id] = times: 0
			Meteor.setTimeout (-> delete recents[user._id] ), 300000