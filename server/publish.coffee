# PUSH ONLY FROM SAME SCHOOL <<<<

# Meteor.publish "usersData", ->
# 	unless @userId? and (callerSchoolId = Meteor.users.findOne(@userId).profile.schoolId)?
# 		@ready()
# 		return

# 	@unblock()

# 	Meteor.users.find { _id: { $ne: @userId }, "profile.schoolId": callerSchoolId }, fields:
# 		"status.online": 1
# 		"status.idle": 1
# 		profile: 1
# 		gravatarUrl: 1

# WARNING: PUSH ALL DATA
Meteor.publish "usersData", ->
	@unblock()
	Meteor.users.find { _id: $ne: @userId }, fields:
		"status.online": 1
		"status.idle": 1
		profile: 1
		gravatarUrl: 1
		hasGravatar: 1

Meteor.publish "userData", ->
	unless @userId?
		@ready()
		return
	
	@unblock()

	return [
		Meteor.users.find(@userId, fields:
			classInfos: 1
			premiumInfo: 1
			magisterCredentials: 1
			schedular: 1
			status: 1
			gravatarUrl: 1
			hasGravatar: 1
			studyGuidesHashes: 1
			profile: 1)
		Schools.find _id: Meteor.users.findOne(@userId).profile.schoolId
	]

Meteor.publish "classes", ->
	@unblock()

	classes = Classes.find()
	if (val = Meteor.users.findOne(@userId)?.profile.courseInfo)?
		{ year, schoolVariant } = val
		classes = Classes.find { schoolVariant, year }

	return classes

Meteor.publish "schools", -> Schools.find()

Meteor.publish "calendarItems", ->
	unless @userId?
		@ready()
		return
	@unblock()
	return CalendarItems.find ownerId: @userId

Meteor.publish "goaledSchedules", -> GoaledSchedules.find { ownerId: @userId }
Meteor.publish "projects", (id) ->
	@unblock()
	if id?
		Projects.find id, participants: @userId
	else
		Projects.find { participants: @userId }, fields:
			name: 1
			magisterId: 1
			classId: 1
			participants: 1

Meteor.publish "roles", -> @unblock(); Meteor.users.find(@userId, fields: roles: 1)