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

			return unless passChanged or mailChanged
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

	BetaPeople.find().observe
		added: (doc) ->
			return if doc.mailSent
			message = "Hey,\n\n" +

			"Cool dat je interesse in simplyHomework hebt!\n" +
			"Elke week worden willekeurig een aantal mensen uitgekozen die binnen worden gelaten.\n" +
			"Je krijgt een email van ons als je in de bèta zit."

			sendMail doc.mail, "simplyHomework | Bèta", message

			BetaPeople.update doc._id, $set: mailSent: yes