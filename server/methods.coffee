request = Meteor.npmRequire 'request'
Future = Npm.require 'fibers/future'

SearchAnalytics = new Mongo.Collection 'searchAnalytics'

Meteor.methods
	###*
	# Streams the file from the given `fromUrl` to the given `destUrl`.
	#
	# @method multipart
	# @param fromUrl {String}
	# @param destUrl {String}
	# @param [options] {Object}
	# @return {Object} { content: String, headers: Object }
	###
	multipart: (fromUrl, destUrl, options = {}) ->
		@unblock()
		check fromUrl, String
		check destUrl, String
		check options, Object
		headers = _.extend (options.headers ? {}), 'User-Agent': 'simplyHomework'
		fut = new Future()

		request(fromUrl).pipe(request {
			method: 'POST'
			url: destUrl
			headers
		}, (error, response, content) ->
			if error? then fut.throw error
			else fut.return { content, headers: response.headers }
		)

		fut.wait()

	changeMail: (mail) ->
		check mail, String
		Meteor.users.update @userId, $set: emails: [ { address: mail, verified: no } ]
		Accounts.sendVerificationEmail user._id

	###*
	# Checks if the given mail address exists in the database.
	# @method mailExists
	# @param mail {String} The address to check.
	# @return {Boolean} Whether or not the given address exists.
	###
	mailExists: (mail) ->
		@unblock()
		check mail, String
		Meteor.users.find(
			{ emails: $elemMatch: address: mail }
			{ fields: '_id': 1 }
		).count() isnt 0

	###*
	# Reports the given user as specified by the given `reportItem`.
	# @method reportUser
	# @param userId {String} The ID of the user the current user (reporter) wants to report.
	# @param reportGrounds {String[]} For what the user has reported this time.
	###
	reportUser: (userId, reportGrounds) ->
		check userId, String
		check reportGrounds, [String]
		old = ReportItems.findOne
			reporterId: @userId
			resolved: no
			userId: userId
			reportGrounds: reportGrounds

		if old?
			throw new Meteor.Error(
				'already-reported'
				"You've already reported the same user on the same grounds."
			)

		# Amount of report items done by the current reporter in the previous 30
		# minutes.
		count = ReportItems.find(
			reporterId: @userId
			time: $gte: new Date _.now() - 1800000
		).count()

		if count > 4
			throw new Meteor.Error 'rate-limit', "You've reported too much users recently."

		reportItem = new ReportItem @userId, userId
		reportItem.reportGrounds = reportGrounds
		ReportItems.insert reportItem

		undefined

	###*
	# Checks if the given `passHash` is correct for the given user.
	# @method checkPasswordHash
	# @param passHash {String} The password hashed with SHA256.
	# @return {Boolean} Whether or not the given `passHash` is correct.
	###
	checkPasswordHash: (passHash) ->
		@unblock()
		check passHash, String

		unless @userId?
			throw new Meteor.Error 'notLoggedIn', 'Client not logged in.'

		user = Meteor.users.findOne @userId
		res = Accounts._checkPassword user,
			digest: passHash
			algorithm: 'sha-256'

		not res.error?

	###*
	# Removes the account of the current caller.
	# @method removeAccount
	# @param passHash {String} The password of the user SHA256 encrypted.
	# @param captchaReponse {String} The response of a captcha by the user.
	###
	removeAccount: (passHash, captchaResponse) ->
		check passHash, String
		check captchaResponse, String

		unless @userId?
			throw new Meteor.Error "notLoggedIn", "User not logged in."

		captchaStatus = reCAPTCHA.verifyCaptcha this.connection.clientAddress, captchaResponse
		unless captchaStatus.data.success
			throw new Meteor.Error "wrongCaptcha", "Captcha was not correct."

		unless Meteor.call 'checkPasswordHash', passHash
			throw new Meteor.Error "wrongPassword", "Given password incorrect."

		Meteor.users.remove @userId

	# TODO: Make search a package with nice search providers and stuff. Which also
	# allows for smart searching, instead of just keyword searching it could use
	# natural language processing to find specefic stuff.

	###*
	# Searches for the given query on as many shit as possible.
	#
	# @method search
	# @param {String} query
	# @param {Object} [options]
	# 	@param {String[]} [classIds]
	# @return {Object[]}
	###
	search: (query, options = {}) ->
		check query, String
		check options, Object
		@unblock()
		orig = query.trim().toLowerCase()
		query = orig.replace /(woordenlijst(en))/g, ''

		userId = @userId
		classInfos = getClassInfos userId
		schoolId = getUserField userId, 'profile.schoolId'

		unless userId?
			throw new Meteor.Error 'notLoggedIn', 'User not logged in.'

		return [] if query.length is 0

		dam = DamerauLevenshtein insert: 0
		calcDistance = (s) -> dam query, s.trim().toLowerCase()

		res = []
		if options.classIds?
			c = Classes.findOne _id: $in: options.classIds
			classInfo = _.find getClassInfos(userId), (info) -> info.id is c._id

			res = res.concat Projects.find({
				participants: userId
				classId: options.classIds
			}, {
				fields:
					participants: 1
					name: 1
					classId: 1

				transform: (p) -> _.extend p,
					type: 'project'
					title: p.name
			}).fetch()

			unless _.contains(orig, 'woordenlijst')
				bookName = Books.findOne(classInfo.bookId)?.title ? ''
				query = "#{normalizeClassName c.name} #{bookName} #{query}"
				res = res.concat Scholieren.getReports(query).map (item) ->
					_.extend item,
						type: 'report'
						filtered: yes

			try
				res = res.concat WoordjesLeren.getBooks(c.externalInfo['woordjesleren'].id).map (item) ->
					_.extend item,
						type: 'wordlist'
						filtered: yes
		else
			res = res.concat Meteor.users.find({
				'profile.firstName': $ne: ''
				'profile.schoolId': schoolId
			}, {
				fields:
					profile: 1

				transform: (u) -> _.extend u,
					type: 'user'
					title: "#{u.profile.firstName} #{u.profile.lastName}"
			}).fetch()

			res = res.concat Projects.find({
				participants: userId
			}, {
				fields:
					participants: 1
					name: 1

				transform: (p) -> _.extend p,
					type: 'project'
					title: p.name
			}).fetch()

			res = res.concat Classes.find({
				_id: $in: (
					_(classInfos)
						.reject 'hidden'
						.pluck 'id'
						.value()
				)
			}, {
				fields:
					name: 1

				transform: (c) -> _.extend c,
					type: 'class'
					title: c.name
			}).fetch()

			res = res.concat [
				#[ 'Overzicht', 'overview' ]
				[ 'Agenda', 'calendar' ]
				[ 'Berichten', 'messages' ]
				[ 'Instellingen', 'settings' ]
			].map ([ name, path, params ], i) ->
				id: i
				type: 'route'
				title: name
				path: path
				params: params

		_(res)
			.filter (obj) ->
				obj.filtered or
				calcDistance(obj.title) < 3 or
				Helpers.contains obj.title, query, yes

			.sortByAll [
				(obj) ->
					titleLower = obj.title.toLowerCase()
					dam = DamerauLevenshtein
						insert: .5
						remove: 2

					distance = _(titleLower)
						.split ' '
						.map (word) -> dam query, word
						.min()

					amount = 0
					# If the name contains a word beginning with the query; lower distance a substensional amount.
					splitted = titleLower.split ' '
					index = _.findIndex splitted, (s) -> s.indexOf(query) > -1
					if index isnt -1
						amount += query.length + (splitted.length - index) * 5

					distance - amount
				'title'
			]

			# amount that is visibile on client is limited to 7, we don't want to send
			# unnecessary data to the client:
			.take 7
			.value()

	'search.analytics.store': (query, choosenId) ->
		@unblock()
		check query, String
		check choosenId, Match.Any

		res = Meteor.call 'search', query
		choosenIndex = _.findIndex res, (x) -> EJSON.equals x._id, choosenId
		res = _.pluck res, 'title'

		SearchAnalytics.insert
			date: new Date
			query: query
			results: res
			choosenIndex: choosenIndex

		undefined

	###*
	# @method enterClassChats
	###
	'enterClassChats': ->
		@unblock()
		userId = @userId

		unless userId?
			throw new Meteor.Error 'notLoggedIn', 'User not logged in.'

		updateCalendarItems userId, Date.today(), Date.today().addDays 14

		user = Meteor.users.findOne userId
		for info in user.classInfos
			calendarItem = CalendarItems.findOne
				classId: info.id
				userIds: userId

			if calendarItem?
				room = ChatRooms.findOne
					classInfo: $exists: yes
					'classInfo.schoolId': user.profile.schoolId
					'classInfo.group': calendarItem.group()

				if room?
					ChatRooms.update room._id, $addToSet:
						users: userId
						'classInfo.ids': info.id
				else
					room = new ChatRoom userId, 'class'
					room.subject = calendarItem.group()
					room.classInfo =
						schoolId: user.profile.schoolId
						group: calendarItem.group()
						ids: [ info.id ]
					ChatRooms.insert room

				if calendarItem.teacher? and info.externalInfo?
					info.externalInfo.teacherName = calendarItem.teacher.name

				Meteor.users.update Meteor.userId(), $pull: classInfos: id: info.id
				Meteor.users.update Meteor.userId(), $push: classInfos: info

	'getPersonStats': ->
		@unblock()

		userId = @userId
		res = []

		inbetweenHoursCount = getInbetweenHours(userId).length
		if inbetweenHoursCount > 0
			res.push "Aantal tussenuren in één week: #{inbetweenHoursCount}"

		res
