import Future from 'fibers/future'
import LRU from 'lru-cache'
import WaitGroup from 'meteor/simply:waitgroup'
import Privacy from 'meteor/privacy'
import { functions } from 'meteor/simply:external-services-connector'

statsCache = LRU
	max: 75
	maxAge: ms.minutes 15
gradeMeanCache = LRU
	max: 100
	maxAge: ms.minutes 5

###*
# Checks if the given `passHash` is correct for the given user.
# @method checkPasswordHash
# @param passHash {String} The password hashed with SHA256.
# @param userId {String}
# @return {Boolean} Whether or not the given `passHash` is correct.
###
@checkPasswordHash = checkPasswordHash = (passHash, userId) ->
	check passHash, String
	check userId, String

	unless userId?
		throw new Meteor.Error 'notLoggedIn', 'Client not logged in.'

	user = Meteor.users.findOne userId
	res = Accounts._checkPassword user,
		digest: passHash
		algorithm: 'sha-256'

	not res.error?

Meteor.methods
	###*
	# @method changeMail
	# @param {String} mail
	# @param {String} passHash
	###
	changeMail: (mail, passHash) ->
		check mail, String
		check passHash, String

		unless @userId?
			throw new Meteor.Error 'not-logged-in'

		unless checkPasswordHash passHash, @userId
			throw new Meteor.Error 'wrong-password', 'Given password incorrect'

		unless Helpers.validMail mail
			throw new Meteor.Error 'invalid-mail'

		Meteor.users.update @userId, $set: emails: [{ address: mail, verified: no }]
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
	# @param extraInfo {String}
	###
	reportUser: (userId, reportGrounds, extraInfo) ->
		check userId, String
		check reportGrounds, [String]
		check extraInfo, String

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
		reportItem.extraInfo = extraInfo
		ReportItems.insert reportItem

		undefined

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
			throw new Meteor.Error 'notLoggedIn'

		captchaStatus = reCAPTCHA.verifyCaptcha this.connection.clientAddress, captchaResponse
		unless captchaStatus.data.success
			throw new Meteor.Error 'wrongCaptcha'

		unless checkPasswordHash passHash, @userId
			throw new Meteor.Error 'wrongPassword'

		Meteor.users.remove @userId

	# TODO: Also run this after adding a new externalService later, this should
	# have an option then to select which services to 'bootstrap'.
	###*
	# @method bootstrapUser
	###
	bootstrapUser: ->
		@unblock()

		userId = @userId
		unless userId?
			throw new Meteor.Error 'not-logged-in', 'User not logged in.'

		event = getEvent 'bootstrapping', userId
		return if event?
		Meteor.users.update userId, $set: 'events.bootstrapping': new Date

		group = new WaitGroup()

		group.defer -> functions.updateGrades userId
		group.defer -> functions.updateStudyUtils userId

		group.defer ->
			functions.updateCalendarItems userId, Date.today(), Date.today().addDays 28 # four weeks
			user = Meteor.users.findOne userId,
				fields:
					classInfos: 1
					'profile.schoolId': 1

			for info in user.classInfos
				calendarItem = CalendarItems.findOne
					classId: info.id
					userIds: userId
					startDate: $gte: Date.today()

				if calendarItem?
					room = ChatRooms.findOne
						users: $ne: userId
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

					Meteor.users.update userId, $pull: classInfos: id: info.id
					Meteor.users.update userId, $push: classInfos: info

		group.wait()
		Meteor.users.update userId,
			$unset: 'events.bootstrapping': yes
			$set: 'events.boostrap': new Date

	'fetchExternalPersonClasses': ->
		userId = @userId
		unless userId?
			throw new Meteor.Error 'not-logged-in', 'User not logged in.'

		classes = functions.getExternalPersonClasses userId
		if classes.length is 0
			throw new Meteor.Error 'no-classes','No external classes found.'

		colors = _.shuffle [
			'#F44336'
			'#E91E63'
			'#9C27B0'
			'#673AB7'
			'#3F51B5'
			'#03A9F4'
			'#009688'
			'#4CAF50'
			'#8BC34A'
			'#CDDC39'
			'#FFEB3B'
			'#FFC107'
			'#FF9800'
			'#FF5722'
		]

		Meteor.users.update userId, $set: classInfos:
			classes.map (c, i) ->
				id: c._id
				color: colors[i % colors.length]
				externalInfo: c.externalInfo
				hidden: no

		undefined

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
				type: 'lesson'
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

			mean = Grades.aggregate([{
				$match:
					ownerId: userId
					isEnd: yes
			}, {
				$group:
					_id: null
					mean: { $avg: "$grade" }
			}])[0]?.mean
			if Number.isFinite mean
				res.push "Het gemiddelde van je eindcijfers is #{mean.toPrecision(2).replace '.', ','}"

			chatMessageCount = ChatMessages.find({
				creatorId: userId
			}).count()
			if chatMessageCount > 0
				res.push "Je hebt in totaal #{chatMessageCount} chatberichten verzonden"

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

	###*
	# @method sharedInbetweenHours
	# @param {String} userId
	# @return CalendarItem[]
	###
	sharedInbetweenHours: (userId) ->
		@unblock()
		check userId, String
		unless @userId?
			@ready()
			return undefined

		if Meteor.users.find(userId).count() is 0
			throw new Meteor.Error 'user-not-found'

		unless Privacy.getOptions(userId).publishCalendarItems
			throw new Meteor.Error 'blocked-by-privacy'

		mine = ScheduleFunctions.getInbetweenHours @userId, yes
		theirs = ScheduleFunctions.getInbetweenHours userId, yes

		_.filter theirs, (x) ->
			m = moment x.start
			_.any mine, (y) -> m.isSame y.start

	###*
	# @method gradeMeans
	# @param {String} gradeId
	# @return {Object} { class: Number, school: Number }
	###
	gradeMeans: (gradeId) ->
		check gradeId, String
		@unblock()
		gradeFunc = (s) => GradeFunctions[s] @userId, gradeId

		res = gradeMeanCache.get gradeId
		unless res?
			res =
				class: gradeFunc 'gradeClassMean'
				school: gradeFunc 'gradeSchoolMean'

			gradeMeanCache.set gradeId, res
		res

	###*
	# @method getInbetweenHours
	# @return {Object[]}
	###
	getInbetweenHours: ->
		@unblock()
		unless @userId?
			return []

		userId = @userId
		ours = ScheduleFunctions.getInbetweenHours userId, yes

		users = Meteor.users.find({
			_id: $ne: userId
			'profile.schoolId': getUserField userId, 'profile.schoolId'
		}, {
			fields:
				_id: 1
				'profile.schoolId': 1
				'settings.privacy': 1
		}).fetch()

		users = _.chain(users)
			.filter (u) -> Privacy.getOptions(u).publishCalendarItems
			.map (user) ->
				_id: user._id
				hours: ScheduleFunctions.getInbetweenHours user._id, yes
			.value()

		_(ours)
			.map (x) ->
				m = moment x.start
				userIds = _(users)
					.filter (u) -> _.some u.hours, (y) -> m.isSame y.start
					.pluck '_id'
					.push userId
					.value()

				userIds: userIds
				start: x.start
				end: x.end
				schoolHour: x.schoolHour
			.value()

	sharedHours: ->
		@unblock()
		unless @userId?
			return []

		hours = CalendarItems.find(
			userIds: @userId
			startDate: $gte: Date.today()
			endDate: $lte: Date.today().addDays 7
			scrapped: no
			schoolHour:
				$exists: yes
				$ne: null
		).map (item) ->
			userIds: item.userIds
			date: item.startDate
			schoolHour: item.schoolHour
			classId: item.classId
			description: item.description

		inbetweenHours = Meteor.call 'getInbetweenHours'

		_(inbetweenHours)
			.map (x) ->
				userIds: x.userIds
				date: x.start
				schoolHour: x.schoolHour
				description: 'Tussenuur'
			.concat hours
			.value()
