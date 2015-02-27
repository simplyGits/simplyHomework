SyncedCron.add
	name: "Clear inactive users"
	schedule: (parser) -> parser.recur().on(3).hour()
	job: ->
		amountUsersRemoved = Meteor.users.remove { "status.lastActivity": $lt: new Date().addDays(-120) }
		usersWarned = Meteor.users.find({ "status.lastActivity": $lt: new Date().addDays(-90) }).fetch()

		for user in usersWarned
			m = "Hey #{user.profile.firstName}!\n\n" +

			"Je hebt al voor #{moment().diff user.status.lastActivity, "days"} dagen niet ingelogd.\n" +
			"Om onze database schoon te houden verwijderen we je account als je niet binnen 30 dagen hebt ingelogd.\n" +
			"Als we je account verwijderd hebben kunnen we het niet terug halen."

			sendMail user, "simplyHomework | inactief account", m

		result = "Warned #{usersWarned.length} inactive users and removed #{amountUsersRemoved} users."
		console.log result
		return result

SyncedCron.add
	name: "Congratulate users"
	schedule: (parser) -> parser.recur().on(5).hour()
	job: ->
		now = new Date
		users = Meteor.users.find( ->
			birthDate = @profile.birthDate
			birthDate.getMonth() is now.getMonth() and birthDate.getDate() is now.getDate()
		).fetch()

		for user in users
			m = "Hey #{user.profile.firstName}!\n\n" +

			"Wij wensen je een fijne verjaardag! :D\n" +
			"Je #{moment().diff user.profile.birthDate, "years"}e was het toch?"

			sendMail user, "simplyHomework | Gefeliciteerd!", m

		result = "Congratulated #{users.length} users."
		console.log result
		return result
