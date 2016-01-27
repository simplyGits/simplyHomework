###*
# Gets persons from the external services matching the given `query` and `type`.
# @method getPersons
# @param {String} query
# @param {String} type
# @param {String} [userId=Meteor.userId()]
# @param {Function} [callback] Required on client.
###
@getPersons = (query, type, userId = Meteor.userId()) ->
	callback = _.last arguments
	if Meteor.isClient
		unless _.isFunction(callback)
			throw new Error 'Callback required on client.'

		if userId isnt Meteor.userId()
			throw new Error 'Client code can only fetch persons using their own account.'

	transform = (arr) -> (_.extend(new ExternalPerson, p) for p in arr)

	res = Meteor.call(
		'getPersons',
		query,
		type,
		userId,
		if callback? then (e, r) -> callback e, (transform r if r?)
	)
	transform res if res?

###*
# Gets profileData per service
# @method getProfileDataPerService
# @param {String} [userId=Meteor.userId()]
# @param {Function} [callback] Required on client.
###
@getProfileDataPerService = ->
	userId = _.find arguments, (a) -> _.isString a
	callback = _.find arguments, (a) -> _.isFunction a
	Meteor.call 'getProfileData', userId ? Meteor.userId(), callback

###*
# Gets the picture of the given `userId`.
# @method picture
# @param [userId=Meteor.userId()] {User|String} The object or ID of the user to get the picture from.
# @param [size=100] {Number} The size in pixels that the gravatar shall be.
# @return {String} A string containing the URL or data string of the picture.
###
@picture = (userId = Meteor.userId(), size = 100) ->
	try
		user = if _.isString(userId) then Meteor.users.findOne(userId) else userId
		info = user.profile.pictureInfo

		switch info.fetchedBy
			when 'gravatar' then "#{info.url}&s=#{size}"
			when 'magister' then info.url
			else throw new Error "Don't know anything about '#{info.fetchedBy}'"

# Issue: #156
@getAvailableBooks = (classId) ->
	clean = (s) -> s.replace(/\W/g, '').toLowerCase()

	c = Classes.findOne classId
	unless c?
		throw new Meteor.Error 'non-existing-class'

	sid = c.externalInfo.scholieren?.id
	Meteor.subscribe 'scholieren.com', sid if sid?

	wid = c.externalInfo.woordjesleren?.id
	Meteor.subscribe 'woordjesleren', wid if wid?

	externalClasses = [
		ScholierenClasses.findOne id: c.externalInfo.scholieren?.id
		WoordjesLerenClasses.findOne id: c.externalInfo.woordjesleren?.id
	]

	res = []
	for c in externalClasses # class from one provider
		for b in c?.books ? [] # loop over every book the new class provides
			oldBook = _.find res, (x) -> clean(x.title) is clean(b.title)

			if oldBook?
				_.defaults oldBook, b
			else
				res.push b

	res
