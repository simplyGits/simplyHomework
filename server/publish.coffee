Meteor.publish "usersData", ->
	Meteor.users.find {}, fields:
		"status.online": 1
		"status.idle": 1
		username: 1
		profile: 1
		gravatarUrl: 1

Meteor.publish "essentials", ->
	userData = Meteor.users.find @userId, fields:
		classInfos: 1
		mailSignup: 1
		hasPremium: 1
		magisterCredentials: 1
		schedular: 1
		hasMagisterSix: 1
	[ Schools.find(), Classes.find(), userData ]

Meteor.publish "goaledSchedules", -> GoaledSchedules.find { ownerId: @userId }
Meteor.publish "projects", -> Projects.find(_participants: @userId)
Meteor.publish "betaPeople", -> BetaPeople.find {}, fields: hash: 1