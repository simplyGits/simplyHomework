Migrations.add
	version: 1
	name: 'Add empty strings on grades without a string'
	up: ->
		Grades.update {
			description: $exists: no
		}, {
			$set: description: ''
		}, {
			multi: true
		}

Migrations.add
	version: 2
	name: 'Remove absenceInfos'
	up: ->
		Absences.remove {}

Meteor.startup ->
	Migrations.migrateTo 'latest'
