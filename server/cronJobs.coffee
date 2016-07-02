Future = require 'fibers/future'
{ sendHtmlMail } = require 'meteor/emails'
{ functions } = require 'meteor/simply:external-services-connector'

# TODO: remind people to finish the setup when they didn't finished it
# TODO: remind people to use the app after a long time of inactivity

# REVIEW: is this actually useful?
###
SyncedCron.add
	# TODO: exclude premium users
	name: 'Clear inactive users'
	schedule: (parser) -> parser.recur().on(3).hour()
	job: ->
		amountUsersRemoved = Meteor.users.remove
			'status.lastActivity': $lt: new Date().addDays -120

		usersWarned = Meteor.users.find(
			'status.lastActivity': $lt: new Date().addDays -90
		).fetch()

		for user in usersWarned
			sendHtmlMail user, 'Inactief account', """
				Hey #{user.profile.firstName}!

				Je hebt al voor #{moment().diff user.status.lastActivity, 'days'} dagen niet ingelogd.
				Om onze database schoon te houden verwijderen we je account als je niet binnen 30 dagen <a href='#{Meteor.absoluteUrl()}login'>ingelogd</a>.
				Als we je account verwijderd hebben kunnen we het niet terug halen.
			"""

		result = "Warned #{usersWarned.length} inactive users and removed #{amountUsersRemoved} users."
		console.log result
		result
###

SyncedCron.add
	# OPTIMIZE
	name: 'Update scholieren.com data'
	schedule: (parser) -> parser.recur().on(4).hour()
	job: ->
		# This job tries to get the scholieren.com data every 5 minutes until we got
		# the data or we hit the try limit (12, which takes 1 hour).

		fut = new Future()

		i = 0
		handle = Helpers.interval (->
			# Try limit exceeded, stop looping.
			if i is 12
				@stop()
				fut.return 'Reached try limit.'
			i += 1

			try
				classes = Scholieren.getClasses().map (c) ->
					name: c.name
					id: c.id
			catch e
				console.error 'Scholieren.getClasses error', e
				return

			# If we don't have ScholierenClasses data yet, we want to insert the
			# classes we currently fetched, even though we don't have the books yet.
			# We will update ScholierenClasses with books when we got them.
			# We don't want to do this when we already have ScholierenClasses tho,
			# otherwise we may overwrite perfectly fine ScholierenClasses _with_
			# books.
			if ScholierenClasses.find().count() is 0
				ScholierenClasses.insert c for c in classes

			try
				books = Scholieren.getBooks()
			catch e
				console.error 'Scholieren.getBooks error', e
				return

			for c in classes
				# Put the matching books inside of the current class.
				c.books = _(books)
					.filter (b) -> b.classId is c.id
					.map (b) ->
						id: b.id
						title: b.title
				c.books = c.books.value() if c.books.value?

				# Update or, if it doesn't currently exist, the scholierenClass in
				# the database.
				ScholierenClasses.upsert { id: c.id }, c

			# We're done here, stop looping.
			@stop()
			fut.return "Successfully updated scholieren.com data on the #{i}th try."
		), 300000 # 5 minutes

		res = fut.wait()
		console.log res
		res

SyncedCron.add
	# OPTIMIZE
	name: 'Update woordjesleren data'
	schedule: (parser) -> parser.recur().on(4).hour()
	job: ->
		# This job tries to get the WoordjesLeren data every 5 minutes until we got
		# the data or we hit the try limit (12, which takes 1 hour).

		fut = new Future()

		i = 0
		handle = Helpers.interval (->
			# Try limit exceeded, stop looping.
			if i is 12
				@stop()
				fut.return 'Reached try limit.'
			i += 1

			try
				classes = WoordjesLeren.getClasses().map (c) ->
					name: c.name
					id: c.id
			catch e
				console.error 'WoordjesLerenClasses.getClasses error', e
				return

			for c in classes
				try
					c.books = WoordjesLeren.getBooks(c.id).map (b) ->
						id: b.id
						title: b.title
						woordjesLerenListCount: b.listCount

				# Update or, if it doesn't currently exist, create the class in the database.
				WoordjesLerenClasses.upsert { id: c.id }, c

			# We're done here, stop looping.
			@stop()
			fut.return "Successfully updated WoordjesLeren data on the #{i}th try."
		), 300000 # 5 minutes

		res = fut.wait()
		console.log res
		res

SyncedCron.add
	name: 'Congratulate users'
	schedule: (parser) -> parser.recur().on(5).hour()
	job: ->
		count = 0

		Meteor.users.find({}, {
			fields:
				'profile.birthDate': 1
				'profile.firstName': 1
				'emails': 1
		}).forEach (user) ->
			birthDate = user.profile.birthDate
			unless birthDate? and Helpers.datesEqual new Date, birthDate
				return

			count++
			sendHtmlMail user, 'Gefeliciteerd!', """
				Hey #{user.profile.firstName}!

				Wij wensen je een fijne verjaardag! :D
				Je #{moment().diff user.profile.birthDate, 'years'}e was het toch?
			"""

		result = "Congratulated #{count} users."
		console.log result
		result

SyncedCron.add
	name: 'Preload users\' schedules for the next two weeks'
	schedule: (parser) -> parser.recur().on(7).hour()
	job: ->
		users = Meteor.users.find({}, fields: _id: 1).fetch()
		for { _id: userId } in users
			functions.updateCalendarItems(
				userId
				Date.today()
				Date.today().addDays 14
			)

SyncedCron.add
	name: 'Handle new schoolyears'
	schedule: (parser) -> parser.recur().on(4).hour()
	job: ->
		userIds = Meteor.users.find({
			'profile.firstName': $ne: ''
		}, {
			fields:
				_id: 1
				'profile.firstName': 1
				emails: 1
		}).map (u) -> u._id

		for userId in userIds
			courses = functions.getCourses userId
			current = _.find courses, (c) -> c.inside new Date
			next = _.find courses, (c) -> c.from > new Date

			if current? and Date.today().addDays(-1) < current.start
				###
				loginUrl = 'https://app.simplyHomework.nl/login'
				sendMail user, 'Nieuw schooljaar', """
					Hey #{user.profile.firstName}!

					Zo te zien is het nieuwe schooljaar zojuist voor je begonnen.
					We hopen dat simplyHomework je dit jaar weer kan helpen met school! :)

					Je moet wel even eerst de setup doorlopen (ongeveer 2 minuten) op: <a href='#{loginurl}'>#{loginurl}</a>

					Success dit schooljaar!
				"""
				###
				Meteor.users.update(
					userId
					$pullAll: setupProgress: [
						'externalServices'
						'extractInfo'
						'getExternalClasses'
					]
				)

			# REVIEW: do we want to send a message here? If so, what?
			# else unless next?
