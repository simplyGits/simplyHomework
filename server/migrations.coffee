{ functions } = require 'meteor/simply:external-services-connector'

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
		}

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

Meteor.startup ->
	Migrations.migrateTo 'latest'
