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

# WARNING: PUSHES ALL DATA
Meteor.publish "usersData", (ids, chatLimit) ->
	@unblock()

	if ids? and ids.length is 1 and ids[0] is @userId
		@ready()
		return

	fields =
		"status.online": 1
		"status.idle": 1
		profile: 1
		gravatarUrl: 1
		hasGravatar: 1

	if ids?
		return [
			Meteor.users.find { _id: $in: _.reject ids, @userId }, fields: fields
			ChatMessages.find({
				to: [ @userId ].concat(ids)
				from: $in: [ @userId ].concat(ids)
			}, { limit: chatLimit }, sort: "time": -1)
		]
	else
		return Meteor.users.find { _id: $ne: @userId }, fields: fields

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
			gradeNotificationDismissTime: 1
			profile: 1)
		Schools.find _id: Meteor.users.findOne(@userId).profile.schoolId

		# All unread chatMessages.
		ChatMessages.find({$or: [{ to: @userId }, { creatorId: @userId }], readBy: $ne: @userId}, sort: "time": -1)
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
Meteor.publish "projects", (id, chatLimit) ->
	@unblock()
	if id?
		[
			Projects.find _id: id, participants: @userId
			ChatMessages.find { projectId: id }, limit: chatLimit, sort: "time": -1
		]
	else
		Projects.find { participants: @userId }, fields:
			name: 1
			magisterId: 1
			classId: 1
			deadline: 1

Meteor.publish "books", (classId) ->
	@unblock()

	unless @userId?
		@ready()
		return

	if classId?
		return Books.find { classId }
	else if _.isNull classId
		return Books.find classId: $in: (x.id for x in (Meteor.users.findOne(@userId).classInfos ? []))
	else
		return Books.find _id: $in: (x.bookId for x in (Meteor.users.findOne(@userId).classInfos ? []))

Meteor.publish "roles", -> @unblock(); Meteor.users.find(@userId, fields: roles: 1)
