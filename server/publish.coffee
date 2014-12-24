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
Meteor.publish "usersData", (ids) ->
	@unblock()

	if ids? and ids.length is 1 and ids[0] is @userId
		@ready()
		return

	query = if ids? then { _id: $in: _.reject(ids, (s) -> s is @userId) } else { _id: $ne: @userId }
	Meteor.users.find query, fields:
		"status.online": 1
		"status.idle": 1
		profile: 1
		gravatarUrl: 1
		hasGravatar: 1

Meteor.publish null, ->
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

	if (val = Meteor.users.findOne(@userId)?.profile.courseInfo)?
		{ year, schoolVariant } = val
		return Classes.find { schoolVariant, year }
	else
		return Classes.find()

Meteor.publish "schools", ->
	@unblock()
	Schools.find()

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
		Projects.find _id: id, participants: @userId
	else
		Projects.find { participants: @userId }, fields:
			name: 1
			magisterId: 1
			classId: 1
			participants: 1

Meteor.publish "books", (classId) ->
	@unblock()

	unless @userId?
		@ready()
		return

	if classId?
		return Books.find { classId }
	else
		return Books.find _id: $in: (x.bookId for x in (Meteor.users.findOne(@userId).classInfos ? []))

Meteor.publish "roles", -> @unblock(); Meteor.users.find(@userId, fields: roles: 1)