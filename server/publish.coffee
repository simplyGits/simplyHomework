# PUSH ONLY FROM SAME SCHOOL <<<<
#
# Meteor.publish "usersData", ->
# 	return unless @userId?
# 	callerSchoolId = Meteor.users.findOne(@userId).profile.schoolId
# 	unless callerSchoolId?
# 		@ready()
# 		return

# 	Meteor.users.find { "profile.schoolId": callerSchoolId }, fields:
# 		"status.online": 1
# 		"status.idle": 1
# 		profile: 1
# 		gravatarUrl: 1

# WARNING: PUSH ALL DATA
Meteor.publish "usersData", ->
	Meteor.users.find {}, fields:
		"status.online": 1
		"status.idle": 1
		profile: 1
		gravatarUrl: 1

Meteor.publish "essentials", ->
	return unless @userId?
	{ year, schoolVariant } = Meteor.users.findOne(@userId).profile.courseInfo

	userData = Meteor.users.find @userId, fields:
		classInfos: 1
		mailSignup: 1
		premiumInfo: 1
		magisterCredentials: 1
		schedular: 1
		hasMagisterSix: 1

		"status.online": 1
		"status.idle": 1
		gravatarUrl: 1
	[ Schools.find(), Classes.find(_schoolVariant: schoolVariant.toLowerCase(), _year: year), userData, CalendarItems.find(_ownerId: @userId) ]

Meteor.publish "goaledSchedules", -> GoaledSchedules.find { ownerId: @userId }
Meteor.publish "projects", -> Projects.find(_participants: @userId)
Meteor.publish "betaPeople", -> BetaPeople.find {}, fields: hash: 1