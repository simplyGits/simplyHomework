@getGradesCursor = (query, userId = Meteor.userId()) ->
	if Meteor.isClient and userId isnt Meteor.userId()
		throw new Error 'Client code can only fetch their own grades.'

	Meteor.call 'updateGrades', userId, no, yes

	StoredGrades.find query

@getStudyUtilsCursor = (query, userId = Meteor.userId()) ->
	if Meteor.isClient and userId isnt Meteor.userId()
		throw new Error 'Client code can only fetch their own utils.'

	Meteor.call 'updateStudyUtils', userId, no, yes

	StudyUtils.find query

@getCalendarItems = (query, userId = Meteor.userId()) ->
	if Meteor.isClient and userId isnt Meteor.userId()
		throw new Error 'Client code can only fetch their own calendarItems.'

	Meteor.call 'updateCalendarItems', userId, no, yes

	CalendarItems.find query

@getPersons = (query, type, userId = Meteor.userId()) ->
	callback = _.last arguments
	if Meteor.isClient and not _.isFunction(callback)
		throw new Error 'Callback required on client.'

	if Meteor.isClient and userId isnt Meteor.userId()
		throw new Error 'Client code can only fetch persons using their own account.'

	trans = (arr) -> (_.extend(new ExternalPerson, p) for p in arr)

	res = Meteor.call(
		'getPersons',
		query,
		type,
		userId,
		if callback? then (e, r) -> callback e, (trans r if r?)
	)
	trans res if res?

@getServicePicture = (service, userId = Meteor.userId()) ->
	check service, String
	check userId, String

	Meteor.users.findOne(userId).externalServices[service].picture

###*
# Gets the gravatar url of the given `userId`.
# @method picture
# @param [userId=Meteor.userId()] {User|ObjectID} The object or ID of the user to get the  from.
# @param [size=100] {Number} The size in pixels that the gravatar shall be.
# @return {String} A string containing the URL of the gravatar.
###
@picture = (userId = Meteor.userId(), size = 100) ->
	user = if _.isString(userId) then Meteor.users.findOne(userId) else userId
	info = user.profile.pictureInfo

	switch info.fetchedBy
		when 'gravatar' then "#{info.url}&s=#{size}"
		when 'magister' then info.url
		else throw new Error "Don't know anything about '#{info.fetchedBy}'"

@gravatar = @picture
