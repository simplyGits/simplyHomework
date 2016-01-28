Meteor.startup ->
	SyncedCron.start()
	reCAPTCHA.config
		privatekey: '6LejzwQTAAAAAKlQfXJ8rpT8vY0fm-6H4-CnZy9M'

	###
	Meteor.AppCache.config
		onlineOnly: [
			'/packages/simply_katex'
			'/audio/smoke'
			'/videos/'
		]
	###

	Accounts.onCreateUser (options, doc) ->
		unless Helpers.correctMail doc.emails[0].address
			throw new Error 'Given mail address is invalid.'

		doc.classInfos = []
		doc.events = {}
		doc.externalServices = {}
		doc.premiumInfo = {}
		doc.setupProgress = []
		doc.settings = {}

		doc.profile =
			firstName: ''
			lastName: ''

		doc

	Projects.find({}, fields: _id: 1, participants: 1).observe
		changed: (newDoc, oldDoc) ->
			if newDoc.participants.length is 0
				Projects.remove newDoc._id

	Meteor.users.find({}, fields: services: 1, emails: 1, 'profile.firstName': 1).observe
		changed: (newDoc, old) ->
			passChanged = old.services.password.bcrypt isnt newDoc.services.password.bcrypt
			mailChanged = old.emails[0].address isnt newDoc.emails[0].address

			if passChanged or mailChanged
				user = if mailChanged then old else newDoc
				message = "Hey #{user.profile.firstName}!\n\n" +
				(
					if passChanged and mailChanged then 'Zojuist is het wachtwoord en het email adres van je account veranderd.\n'
					else if passChanged and not mailChanged then 'Zojuist is het wachtwoord van je account veranderd.\n'
					else if not passChanged and mailChanged then 'Zojuist is het mail adres van je account veranderd.\n'
				) +
				'Als je dit zelf was kan je dit bericht negeren en het uitprinten en als papieren vliegtuigje gebruiken ofzo.\n' +
				'Als je dit niet was heb je 2 opties:\n'+
				'- Rondjes rennen.\n' +
				'- Emailtje terug sturen (<a href=\'mailto:hello@simplyApps.nl\'>hello@simplyApps.nl</a>)'

				subject = (
					if passChanged and mailChanged then 'Wachtwoord en Mail Adres Veranderd'
					else if passChanged and not mailChanged then 'Wachtwoord Veranderd'
					else if not passChanged and mailChanged then 'Mail Adres Veranderd'
				)

				sendMail user, "simplyHomework | #{subject}", message

	users = {}
	olderThan = (val, min) -> val? and _.now() - val > min
	Accounts.onLoginFailure ({ user, error }) ->
		return unless error.error is 403 and user?
		val = users[user._id]

		# Create a new user entry if we don't have one yet, or if the current login
		# attempt wasn't in great succession (5 minutes) of the first one.
		# Unless we have sent an warning in the previous 24 hours.
		if not val? or
		(val.times < 5 and olderThan(val.when, 300000)) or
		olderThan(val.mailSentAt, 86400000)
			val =
			users[user._id] =
				times: 0
				when: _.now()
				mailSentAt: null

		if ++val.times >= 5 and not val.mailSentAt?
			sendMail user, 'simplyHomework | Account mogelijk in gevaar', """
				Hey #{user.profile.firstName},

				Pas heeft iemand in een korte tijd meerdere keren een fout wachtwoord ingevuld.
				Als jij dit niet was en je wachtwoord is zwak, verander hem dan zo snel mogelijk in <a href='#{Meteor.absoluteUrl()}'>simplyHomework</a>.
				Als jij dit wel was en je bent je wachtwoord vergeten kan je het <a href='#{Meteor.absoluteUrl()}forgot'>hier</a> veranderen.
			"""

			val.mailSentAt = _.now()

	Grades._ensureIndex
		ownerId: 1
		dateFilledIn: -1
		classId: 1
		grade: 1

	Meteor.users._ensureIndex
		'profile.schoolId': 1
		'profile.firstName': 1
		'profile.lastName': 1
