{ functions } = require 'meteor/simply:external-services-connector'
{ sendHtmlMail } = require 'meteor/emails'

Migrations.add
	version: 1
	name: 'Add empty strings on grades without a string'
	up: ->
		Grades.update {
			description: $exists: no
		}, {
			$set: description: ''
		}, {
			multi: yes
		}

Migrations.add
	version: 2
	name: 'Remove absenceInfos'
	up: ->
		Absences.remove {}

Migrations.add
	version: 3
	name: 'Remove all file related things'
	up: ->
		calendarItemIds = CalendarItems.find(
			fileIds: $ne: []
		).map (ci) -> ci._id
		CalendarItems.remove _id: $in: calendarItemIds
		Absences.remove calendarItemId: $in: calendarItemIds

		Files.remove {}
		FileDownloadCounters.remove {}
		Messages.remove {}
		StudyUtils.remove {}

Migrations.add
	version: 4
	name: 'Fetch messages and mark all messages as notified'
	up: ->
		users = Meteor.users.find({}).fetch()
		users.forEach (user) ->
			functions.updateMessages user._id, 0, [ 'inbox' ]

		Messages.update {}, {
			$set: notifiedOn: new Date
		}, {
			multi: yes
		}

Migrations.add
	version: 5
	name: 'Fetch studyGuides for all persons'
	up: ->
		users = Meteor.users.find({}).fetch()
		users.forEach (user) ->
			functions.updateStudyUtils user._id, yes

Migrations.add
	version: 6
	name: 'Remove previousValues on grades where previousValues is useless'
	up: ->
		grades = Grades.find(previousValues: $exists: true).fetch()
		keys = [ 'dateFilledIn', 'grade', 'gradeStr', 'weight' ]

		Grades.update {
			_id: $in: (
				_(grades)
					.filter (g) -> _.every keys, (k) -> g[k] is g.previousValues[k]
					.pluck '_id'
					.value()
			)
		}, {
			$unset:
				previousValues: yes
		}, validate: no

Migrations.add
	version: 7
	name: "Remove 'created' event in private chatrooms"
	up: ->
		ChatRooms.update {
			type: 'private'
		}, {
			$pull: events:
				type: 'created'
		}, {
			multi: yes
		}

Migrations.add
	version: 8
	name: 'Mark all non-read messages as notified'
	up: ->
		Messages.update {
			notifiedOn: null
		}, {
			$set: notifiedOn: new Date
		}, {
			multi: yes
		}

Migrations.add
	version: 9
	name: 'Send email explaining bug to every person'
	up: ->
		users = Meteor.users.find({
			'externalServices.magister': $exists: true
		}).fetch()
		for user in users
			sendHtmlMail user, 'Technische storing', """
				Hey #{user.profile.firstName}!

				Door een technische fout hebben we onterecht een groot aantal mails van oude Magister berichten verzonden.
				Onze excuses als dit bij jou ook het geval is en we je inbox overhoop gegooid hebben.
			"""

Migrations.add
	version: 10
	name: 'Update calendarItems in the database to the new service format'
	up: ->
		for item in CalendarItems.find({}).fetch()
			CalendarItems.update item._id, {
				$set:
					externalInfos:
						"#{item.fetchedBy}": id: item.externalId
				$unset:
					fetchedBy: yes
					externalId: yes
			}, {
				validate: no
			}, (e) ->
				console.log "error for item with id '#{item._id}'", e if e?

Migrations.add
	version: 11
	name: "Remove 'calendarItemsUpdate' user events"
	up: ->
		Meteor.users.update {}, {
			$unset:
				'events.calendarItemsUpdate': yes
		}, {
			multi: yes
		}

Migrations.add
	version: 12
	name: 'Give ChatMessages a changes field'
	up: ->
		ChatMessages.find({}, {
			transform: null
		}).forEach (m) ->
			ChatMessages.update m._id, {
				$set:
					changes: (
						res = []
						if m.changedOn?
							res.push
								date: m.changedOn
								new: m.content
						res
					)
				$unset:
					changedOn: yes
			}, validate: no
	down: ->
		ChatMessages.find({
			changes: $ne: []
		}, {
			transform: null
		}).forEach (m) ->
			ChatMessages.update m._id, {
				$set:
					changedOn: _.last(m.changes)?.date
				$unset:
					changes: yes
			}, validate: no

Migrations.add
	version: 13
	name: "Add 'into', 'cookies' and 'first-use' to setupProgress of everybody who ran setup"
	up: ->
		Meteor.users.update {
			setupProgress: $ne: []
		}, {
			$addToSet:
				setupProgress: $each: [
					'intro'
					'cookies'
					'first-use'
				]
		}, {
			multi: yes
		}

Migrations.add
	version: 14
	name: 'Make previousValues field on Grade an array'
	up: ->
		Grades.find({
			previousValues: $exists: yes
		}).forEach (g) ->
			Grades.update g._id,
				$set: previousValues: [
					g.previousValues
				]

		Grades.update {
			previousValues: $exists: no
		}, {
			$set: previousValues: []
		}, {
			multi: yes
		}

	down: ->
		Grades.find({
			previousValues: $ne: []
		}).forEach (g) ->
			Grades.update g._id,
				$set: previousValues: _.last g.previousValues

		Grades.update {
			previousValues: []
		}, {
			$unset: previousValues: yes
		}, {
			multi: yes
		}

Migrations.add
	version: 15
	name: 'add compiledContent field to chatMessages'
	up: ->
		ChatMessages.find({}).forEach (m) ->
			ChatMessages.update m._id,
				$set:
					compiledContent: m.content
					content: m.content.replace /<[^>]+>/g, ''

Migrations.add
	version: 16
	name: 'remove gone users from chat rooms'
	up: ->
		userIds = Meteor.users.find({}).map (u) -> u._id

		rooms = ChatRooms.find(
			type: $ne: 'private'
		).fetch()
		roomsUserIds = _.chain(rooms)
			.pluck 'users'
			.flatten()
			.uniq()
			.value()

		leftoverUserIds = _.difference roomsUserIds, userIds
		for userId in leftoverUserIds
			ChatRooms.update {
				users: userId
			}, {
				$pull: users: userId
			}, {
				multi: yes
			}

Migrations.add
	version: 17
	name: 'compile chat messages containing katex equations'
	up: ->
		middleware = _.find ChatMiddlewares._middlewares, name: 'katex'

		messages = ChatMessages.find(
			content: $regex: /\$\$(.+?)\$\$/g
		).fetch()
		for message in messages
			ChatMessages.update message._id,
				$set:
					compiledContent: middleware.fn(message).compiledContent

Migrations.add
	version: 18
	name: 'set hidden field on serviceUpdates'
	up: ->
		ServiceUpdates.update {}, {
			$set: hidden: no
		}, {
			multi: yes
		}

Migrations.add
	version: 19
	name: 'fix typo in bootstrap event name'
	up: ->
		users = Meteor.users.find({
			'events.boostrap': $exists: yes
		}).fetch()

		for user in users
			date = user.events.boostrap
			Meteor.users.update user._id,
				$unset: 'events.boostrap': yes
				$set: 'events.bootstrap': date

Meteor.startup ->
	Migrations.migrateTo 'latest'
