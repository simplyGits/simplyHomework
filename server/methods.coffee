request = Meteor.npmRequire 'request'
Future = Npm.require 'fibers/future'

Meteor.methods
	###*
	# Do a HTTP request.
  #
	# @method http
	# @param method {String} The HTTP method to use.
	# @param url {String} The URL to send the HTTP request to.
	# @param options {Object} A request settings object.
	# @return {Object} { content: String, headers: Object }
	###
	http: (method, url, options = {}) ->
		@unblock()
		headers = _.extend (options.headers ? {}), 'User-Agent': 'simplyHomework'
		fut = new Future()

		opt = _.extend options, {
			method
			url
			headers
			jar: no
			body: options.data ? options.content
			json: options.data?
			encoding: if _.isUndefined(options.encoding) then 'utf8' else options.encoding
		}

		request opt, (error, response, content) ->
			if error? then fut.throw error
			else fut.return { content, headers: response.headers }

		fut.wait()

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
		Meteor.users.update @userId, $set: { "emails": [ { address: mail, verified: no } ] }
		Meteor.call "callMailVerification"

	###*
	# Verifies the given address, or if none is given, the address of the current
	# logged in user.
	#
	# @method callMailVerification
	# @param [adress] {String} The adress to verify, if this is omitted the first address of the current user (`this.userId`) will be used.
	###
	callMailVerification: (address) ->
		user = (
			if address?
				Meteor.users.findOne emails: $elemMatch: { address }
			else
				Meteor.users.findOne @userId
		)
		unless user?
			throw new Meteor.Error 'notFound', 'User not found.'

		if user.emails[0].verified
			throw new Meteor.Error 'alreadyVerified', 'Mail already verified.'
		else
			Accounts.sendVerificationEmail user._id

	###*
	# Checks if the given mail address exists in the database.
	# @method mailExists
	# @param mail {String} The address to check.
	# @return {Boolean} Whether or not the given address exists.
	###
	mailExists: (mail) ->
		@unblock()
		Meteor.users.find(emails: $elemMatch: address: mail).count() isnt 0

	###*
	# Reports the given user as specified by the given `reportItem`.
	# @method reportUser
	# @param reportItem {ReportItem} The reportItem to store.
	###
	reportUser: (reportItem) ->
		old = ReportItems.findOne
			reporterId: @userId
			userId: reportItem.userId

		if old?
			ReportItems.update reportItem._id, $set:
				reportGrounds: _.union old.reportGrounds, reportItem.reportGrounds
				time: new Date()

		else
			# Amount of report items done by the current reporter in the previous 30
			# minutes.
			count = ReportItems.find(
				reporterId: @userId
				time: $gte: new Date _.now() - 1800000
			).count()

			if count > 4
				throw new Meteor.Error 'rateLimit', "You've reported too much users recently."

			ReportItems.insert reportItem

		undefined

	# TODO: Maybe ratelimit this method, so that people can't use it to bruteforce
	# or smth.
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

	storePlannerPrefs: (obj) ->
		@unblock()
		return if not @userId or _.isEmpty obj
		check obj, Object

		user = Meteor.users.findOne @userId
		original = user.plannerPrefs ? {}

		Meteor.users.update @userId, $set: plannerPrefs: _.extend original, obj
		undefined
