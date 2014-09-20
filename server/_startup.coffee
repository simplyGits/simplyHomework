@ExecutedCommands = new Meteor.Collection "exectuedCommands"

Meteor.startup ->
	process.env.MAIL_URL = "smtp://lieuwerooijakkers@gmail.com:gV1afFmrhN7IUG7VS-x89w@smtp.mandrillapp.com:587" # == STAGING ==

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
			return if old.services.password.bcrypt is newDoc.services.password.bcrypt
			user = Meteor.users.findOne newDoc._id
			message = "Hey #{user.profile.firstName}!\n\n" +

			"Zojuist is het wachtwoord van je account veranderd.\n" +
			"Als je dit zelf was kan je dit bericht negeren en het uitprinten en als papieren vliegtuigje gebruiken ofzo.\n" +
			"Als je dit niet was heb je 2 opties:\n"+
			"- Rondjes rennen.\n" +
			"- Emailtje terug sturen (<a href=\"mailto:hello@simplyApps.nl\">hello@simplyApps.nl</a>)"

			sendMail user, "simplyHomework | Wachtwoord Veranderd", message

	BetaPeople.find().observe
		added: (doc) ->
			return if doc.mailSent
			message = "Hey,\n\n" +

			"Cool dat je interesse in simplyHomework hebt!\n" +
			"Elke week worden willekeurig een aantal mensen uitgekozen die worden binnen gelaten.\n" +
			"Je krijgt een email van ons als je in de bèta zit."

			sendMail doc.mail, "simplyHomework | Bèta", message

			BetaPeople.update doc._id, $set: mailSent: yes