Meteor.startup ->
	Accounts.urls.verifyEmail = (token) -> Meteor.absoluteUrl "verify/#{token}"
	Accounts.urls.resetPassword = (token) -> Meteor.absoluteUrl "reset/#{token}"

	Accounts.emailTemplates.siteName = 'simplyHomework.nl'
	Accounts.emailTemplates.from = 'simplyHomework <hello@simplyApps.nl>'

	Accounts.emailTemplates.resetPassword.subject = (user) -> 'simplyHomework | Wachtwoord'
	Accounts.emailTemplates.resetPassword.html = (user, url) ->
		getMail """
			Hey #{user.profile.firstName}!

			Je was je wachtwoord vergeten, hier krijg je een nieuwe:
			<a href='#{url}'>#{url}</a>
		""",
			'@context': 'http://schema.org'
			'@type': 'EmailMessage'
			description: 'Wachtwoord opnieuw instellen'
			potentialAction:
				'@type': 'ViewAction'
				target: url
				name: 'Herstel wachtwoord'

	Accounts.emailTemplates.verifyEmail.subject = (user) -> 'simplyHomework | Nieuw Account'
	Accounts.emailTemplates.verifyEmail.html = (user, url) ->
		getMail """
			Hey!

			Welkom bij simplyHomework! Klik, om je account te verifiëren, op deze link:
			<a href='#{url}'>#{url}</a>
		""",
			'@context': 'http://schema.org'
			'@type': 'EmailMessage'
			description: 'Account verifiëren'
			potentialAction:
				'@type': 'ViewAction'
				target: url
				name: 'Verifieer account'
