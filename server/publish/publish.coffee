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
Meteor.publish "usersData", (ids) ->
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
		return Meteor.users.find { _id: $in: _.reject ids, @userId }, fields: fields
	else
		return Meteor.users.find { _id: $ne: @userId }, fields: fields

Meteor.publish "chatMessages", (data, limit) ->
	@unblock()

	unless @userId?
		@ready()
		return

	# Makes sure we're getting a number in a base of of 10.
	#
	# This shouldn't be needed since the client only increments
	# the limit by ten, but we want to make sure it is server
	# side too, we limit it to a power of ten to minimize the
	# amount of unique cursors.
	limit = limit + 10 - limit % 10

	if data.userId?
		ChatMessages.find({
			$or: [
				{
					creatorId: data.userId
					to: @userId
				}
				{
					creatorId: @userId
					to: data.userId
				}
			]
		}, { limit, sort: "time": -1 } )
	else
		# Check if the user is inside the project. #veiligheidje
		if Projects.find(_id: data.projectId, participants: @userId).count() is 0
			@ready()
			return

		ChatMessages.find({
			projectId: data.projectId
		})

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

		Projects.find { participants: @userId }, fields:
			name: 1
			magisterId: 1
			classId: 1
			deadline: 1

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
Meteor.publish "projects", (id) ->
	@unblock()

	if Projects.find(_id: id, participants: @userId).count() is 0
		@ready()
		return

	return [
		Projects.find _id: id, participants: @userId
		ChatMessages.find { projectId: id }, limit: 1, sort: "time": -1 # Just the last message to show on the projectView.
	]

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

id = new Meteor.Collection.ObjectID()
Meteor.publish "userCount", ->
	@unblock()
	count = 0
	loaded = no

	pub = @
	handle = Meteor.users.find().observeChanges
		added: ->
			count++
			if loaded then pub.changed "userCount", id, count: count

		removed: ->
			count--
			if loaded then pub.changed "userCount", id, count: count

	loaded = yes
	@added "userCount", id, count: count
	@ready()

	@onStop ->
		handle.stop()

Meteor.publish "scholieren.com", ->
	@unblock()
	@added("scholieren.com", c.id, c) for c in ScholierenClasses.get()
	@ready()
