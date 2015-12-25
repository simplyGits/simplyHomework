@getInbetweenHours = (userId = Meteor.userId()) ->
	res = []
	hours = CalendarItems.find(
		userIds: userId
		startDate: $gte: Date.today()
		endDate: $lte: Date.today().addDays 7
		schoolHour:
			$exists: yes
			$ne: null
	).fetch()

	for daydelta in [0...7]
		date = Date.today().addDays daydelta
		items = _(hours)
			.filter (item) -> item.startDate.date().getTime() is date.getTime()
			.sortBy 'startDate'
			.value()

		if items.length > 0
			# REVIEW: Use mean?
			timeThreshold = items[0].endDate.getTime() - items[0].startDate.getTime()

			endPrev = undefined
			for item in items
				timeSpan = (
					if endPrev? then item.startDate.getTime() - endPrev.getTime()
					else 0
				)
				amount = ~~(timeSpan / timeThreshold)
				for i in [0...amount]
					res.push
						start: new Date(endPrev.getTime() + timeThreshold * i)
						end: new Date(endPrev.getTime() + timeThreshold * ( 1 + i ))

				endPrev = item.endDate

	Debug.logThrough res

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

@getProfileDataPerService = ->
	userId = _.find arguments, (a) -> _.isString a
	callback = _.find arguments, (a) -> _.isFunction a
	Meteor.call 'getProfileData', userId ? Meteor.userId(), callback

# TODO: Fix this, we don't want to sent all the externalService data to the
# client for security reasons.
@getServicePicture = (service, userId = Meteor.userId()) ->
	check service, String
	check userId, String

	Meteor.users.findOne(userId).externalServices[service].picture

###*
# Gets the picture of the given `userId`.
# @method picture
# @param [userId=Meteor.userId()] {User|ObjectID} The object or ID of the user to get the picture from.
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
@getAvailableClasses = ->
	clean = (s) -> s.replace(/\W/g, '').toLowerCase()

	Meteor.subscribe 'scholieren.com'
	Meteor.subscribe 'woordjesleren'

	res = []
	results = [
		ScholierenClasses.find().fetch()
		WoordjesLerenClasses.find().fetch()
	]

	for result in results
		for c in result
			classBase = _.find res, (x) -> clean(x.name) is clean(c.name)
			if classBase?
				_.defaults classBase, c
			else
				res.push c
				classBase = c

			for b in c.books ? []
				bookBase = _.find classBase.books, (x) ->
					console.log x, b
					clean(x.title) is clean(b.title)
				if bookBase?
					_.defaults bookBase, b
				else
					classBase.books.push c

	res
