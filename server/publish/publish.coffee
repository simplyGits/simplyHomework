# PUSH ONLY FROM SAME SCHOOL <<<<
#Meteor.publish 'usersData', (ids) ->
#	@unblock()
#	userId = @userId
#	schoolId = Meteor.users.findOne(userId)?.profile.schoolId
#
#	# We don't have to handle shit if we are only asked for the current user, no
#	# users at all or the current user doesn't have a school.
#	if (not schoolId?) or (ids? and ids.length <= 1 and ids[0] is userId)
#		@ready()
#		return undefined
#
#	Meteor.users.find {
#		_id: (
#			if ids? then { $in: _.reject ids, userId }
#			else { $ne: userId }
#		)
#		'profile.firstName': $ne: ''
#		'profile.schoolId': schoolId
#	}, fields:
#		'status.online': 1
#		'status.idle': 1
#		profile: 1

# WARNING: PUSHES ALL DATA
Meteor.publish 'usersData', (ids) ->
	@unblock()
	userId = @userId

	# We don't have to handle shit if we are only asked for the current user or no
	# users at all.
	if ids? and ids.length <= 1 and ids[0] is userId
		@ready()
		return undefined

	Meteor.users.find {
		_id: (
			if ids? then { $in: _.reject ids, userId }
			else { $ne: userId }
		)
		'profile.firstName': $ne: ''
	}, fields:
		'status.online': 1
		'status.idle': 1
		profile: 1

Meteor.publish "chatMessages", (data, limit) ->
	@unblock()

	unless @userId?
		@ready()
		return undefined

	# Makes sure we're getting a number in a base of of 10.
	#
	# This shouldn't be needed since the client only increments
	# the limit by ten, but we want to make sure it is server
	# side too, we limit it to a power of ten to minimize the
	# amount of unique cursors.
	limit = limit + 9 - (limit - 1) % 10

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
			return undefined

		ChatMessages.find({
			projectId: data.projectId
		}, { limit, sort: "time": -1 })

Meteor.publish null, ->
	unless @userId?
		@ready()
		return undefined

	@unblock()

	[
		Meteor.users.find(@userId, fields:
			classInfos: 1
			creationDate: 1
			externalServices: 1
			gradeNotificationDismissTime: 1
			magisterCredentials: 1
			plannerPrefs: 1
			premiumInfo: 1
			profile: 1
			status: 1
			studyGuidesHashes: 1)
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
	unless @userId?
		@ready()
		return undefined

	@unblock()

	coursInfo = Meteor.users.findOne(@userId).profile.courseInfo
	if courseInfo?
		{ year, schoolVariant } = courseInfo
		Classes.find { schoolVariant, year }
	else
		Classes.find()

Meteor.publish "schools", ->
	@unblock()
	Schools.find {}, fields: externalId: 1

Meteor.publish "calendarItems", ->
	unless @userId?
		@ready()
		return undefined

	@unblock()
	CalendarItems.find ownerId: @userId

Meteor.publish "goaledSchedules", -> GoaledSchedules.find { ownerId: @userId }
Meteor.publish "projects", (id) ->
	unless @userId?
		@ready()
		return undefined

	@unblock()

	if Projects.find(_id: id, participants: @userId).count() is 0
		@ready()
		return undefined

	[
		Projects.find _id: id, participants: @userId
		ChatMessages.find { projectId: id }, limit: 1, sort: "time": -1 # Just the last message to show on the projectView.
	]

Meteor.publish "books", (classId) ->
	unless @userId?
		@ready()
		return undefined

	@unblock()

	if classId?
		Books.find { classId }
	else if _.isNull classId
		Books.find classId: $in: (x.id for x in (Meteor.users.findOne(@userId).classInfos ? []))
	else
		Books.find _id: $in: (x.bookId for x in (Meteor.users.findOne(@userId).classInfos ? []))

Meteor.publish "roles", ->
	unless @userId?
		@ready()
		return undefined

	@unblock()
	Meteor.users.find(@userId, fields: roles: 1)

Meteor.publish "userCount", ->
	@unblock()
	Counts.publish this, "userCount", Meteor.users.find()
	undefined

Meteor.publish "scholieren.com", ->
	unless @userId?
		@ready()
		return undefined
	ScholierenClasses.find()
