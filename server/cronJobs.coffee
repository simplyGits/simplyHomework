SavedHomework = new Meteor.Collection "savedHomework"

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
	name: 'Update scholieren.com data'
	schedule: (parser) -> parser.recur().on(4).hour()
	job: ->
		# This job tries to get the scholieren.com data every 5 minutes until we got
		# the data or we hit the try limit (12, which takes 1 hour).

		i = 0
		handle = Helpers.interval (->
			Scholieren.getClasses (e, classes = []) =>
				console.error 'Scholieren.getClasses error', e if e?
				return if e?

				# If we don't have ScholierenClasses data yet, we want to insert the
				# classes we currently fetched, even though we don't have the books yet.
				# We will update ScholierenClasses with books when we got them.
				# We don't want to do this when we already have ScholierenClasses tho,
				# otherwise we may overwrite perfectly fine ScholierenClasses _with_
				# books.
				if ScholierenClasses.find().count() is 0
					ScholierenClasses.insert c for c in classes

				Scholieren.getBooks (e, books = []) =>
					console.error 'Scholieren.getBooks error', e if e?
					return if e?

					for c in classes
						# Put the matching books inside of the current class.
						c.books = _.filter books, (b) -> b.classId is c.id

						# Update or, if it doesn't currently exist, the scholierenClass in
						# the database.
						ScholierenClasses.upsert { id: c.id }, c

					# We're done here, stop looping.
					@stop()

			# Try limit exceeded, stop looping.
			@stop() if i is 12
			i++
		), 300000 # 5 minutes

SyncedCron.add
	name: "Congratulate users"
	schedule: (parser) -> parser.recur().on(5).hour()
	job: ->
		users = Meteor.users.find(
			"this.profile.birthDate != null &&" +
			"this.profile.birthDate.getMonth() === new Date().getMonth() &&" +
			"this.profile.birthDate.getDate() === new Date().getDate()"
		).fetch()

		for user in users
			m = "Hey #{user.profile.firstName}!\n\n" +

			"Wij wensen je een fijne verjaardag! :D\n" +
			"Je #{moment().diff user.profile.birthDate, "years"}e was het toch?"

			sendMail user, "simplyHomework | Gefeliciteerd!", m

		result = "Congratulated #{users.length} users."
		console.log result
		return result
