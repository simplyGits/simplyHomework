request = Meteor.npmRequire 'request'
Future = Npm.require 'fibers/future'

statsCache = LRU
	max: 75
	maxAge: 1000 * 60 * 15 # 15 minutes
gradeMeanCache = LRU
	max: 100
	maxAge: 1000 * 60 * 60 # 1 hour

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
		Accounts.sendVerificationEmail @userId

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

	###*
	# @method bootstrapUser
	###
	'bootstrapUser': ->
		@unblock()
		userId = @userId

		unless userId?
			throw new Meteor.Error 'notLoggedIn', 'User not logged in.'

		updateCalendarItems userId, Date.today(), Date.today().addDays 14
		user = Meteor.users.findOne userId,
			fields:
				classInfos: 1
				'profile.schoolId': 1

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
					ChatRooms.update room._id,
						$addToSet:
							users: userId
							'classInfo.ids': info.id
							events:
								type: 'joined'
								userId: userId
								time: new Date
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

		updateGrades userId
		updateStudyUtils userId

	'getPersonStats': ->
		@unblock()
		userId = @userId

		res = statsCache.get userId
		unless res?
			{ firstName, schoolId } = Meteor.users.findOne(userId).profile
			res = []
			hours = CalendarItems.find({
				userIds: userId
				startDate: $gte: Date.today()
				endDate: $lte: Date.today().addDays 7
				schoolHour:
					$exists: yes
					$ne: null
			}, {
				fields:
					userIds: 1
			}).fetch()
			users = Meteor.users.find({
				_id: $ne: userId
				'profile.firstName': firstName
			}, {
				fields:
					'profile.firstName': 1
					'profile.schoolId': 1
			}).fetch()

			if hours.length > 0
				res.push "Aantal lesuren in één week: #{hours.length}"

			if users.length > 1
				s = "Er zijn #{users.length} anderen die ook #{firstName} heten op simplyHomework"

				filtered = _.filter users, (u) -> u.profile.schoolId is schoolId
				if filtered.length > 0
					s += " (waarvan #{filtered.length} van jouw school)"

				res.push s

			inbetweenHoursCount = ScheduleFunctions.getInbetweenHours(userId).length
			if inbetweenHoursCount > 0
				res.push "Aantal tussenuren in één week: #{inbetweenHoursCount}"

			frequent = _(hours)
				.pluck 'userIds'
				.flatten()
				.without userId
				.countBy()
				.pairs()
				.max _.last

			if _.isArray(frequent)
				user = Meteor.users.findOne frequent[0]
				if user?
					path = FlowRouter.path 'personView', id: user._id
					link = "<a href='#{path}'>#{user.profile.firstName} #{user.profile.lastName}</a>"

					res.push "Je deelt de meeste lessen met #{link}"

			grades = GradeFunctions.getAllGrades yes, userId
			if grades.length > 0
				mean = _(grades)
					.pluck 'grade'
					.compact()
					.mean()
					.value()

				res.push "Het gemiddelde van je eindcijfers is #{mean.toFixed(1).replace '.', ','}"

			statsCache.set userId, res

		res

	###*
	# @method insertTicket
	# @param {String} body
	###
	insertTicket: (body) ->
		check body, String
		body = body.trim()
		if body.length is 0
			throw new Meteor.Error 'empty-body'

		Tickets.insert new Ticket body, @userId

	sharedInbetweenHours: (userId) ->
		@unblock()
		check userId, String
		unless @userId?
			@ready()
			return undefined

		if Meteor.users.find(userId).count() is 0
			throw new Meteor.Error 'user-not-found'

		mine = ScheduleFunctions.getInbetweenHours @userId, yes
		theirs = ScheduleFunctions.getInbetweenHours userId, yes

		_.filter theirs, (x) ->
			m = moment x.start
			_.any mine, (y) -> m.isSame y.start

	gradeSchoolMean: (gradeId) ->
		check gradeId, String
		@unblock()

		res = gradeMeanCache.get gradeId
		unless res?
			grade = Grades.findOne
				_id: gradeId
				ownerId: @userId
			unless grade?
				throw new Meteor.Error 'not-found'

			schoolGrades = Grades.find(
				description: grade.description
				weight: grade.weight
				classId: grade.classId
				'period.id': grade.period.id
			).fetch()

			res = _(schoolGrades)
				.pluck 'grade'
				.compact()
				.mean()
				.value()

			gradeMeanCache.set gradeId, res

		res
