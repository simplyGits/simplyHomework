request = Meteor.npmRequire "request"
Future = Npm.require "fibers/future"

Meteor.methods
	http: (method, url, options = {}) ->
		@unblock()
		headers = _.extend (options.headers ? {}), "User-Agent": "simplyHomework"
		fut = new Future()

		opt = {
			method
			url
			headers
			jar: no
			body: options.data ? options.content
			json: options.data?
			encoding: if _.isUndefined(options.encoding) then "utf8" else options.encoding
		}

		request opt, (error, response, content) ->
			if error? then fut.throw error
			else fut.return { content, headers: response.headers }

		fut.wait()
	
	log: (type, message, elements...) -> console[type] message, elements...

	setMagisterInfo: (info) ->
		@unblock()
		userId = @userId
		{ username, password } = info.magisterCredentials
		try
			HTTP.post "#{info.school.url}/api/sessie",
				data:
					"Gebruikersnaam": username
					"Wachtwoord": password
					"IngelogdBlijven": no
				headers:
					"Content-Type": "application/json;charset=UTF-8"

			new Magister(info.school, username, password, no).ready ->
				url = @profileInfo().profilePicture(200, 200, yes)

				request.get { url, encoding: null, headers: cookie: @http._cookie }, Meteor.bindEnvironment (error, response, body) =>
					Meteor.users.update userId,
						$set:
							"magisterCredentials": info.magisterCredentials
							"profile.schoolId": info.schoolId
							"profile.magisterPicture": if body? then "data:image/jpg;base64,#{body.toString "base64"}" else ""
							"profile.birthDate": @profileInfo().birthDate()
			return yes
		catch
			return no

	clearMagisterInfo: -> Meteor.users.update @userId, $set: magisterCredentials: null

	changeMail: (mail) ->
		Meteor.users.update @userId, $set: { "emails": [ { address: mail, verified: no } ] }
		Meteor.call "verifyMail"

	verifyMail: (address) ->
		user = if address? then Meteor.users.findOne { "emails": $elemMatch: { address }} else Meteor.users.findOne @userId

		if user.emails[0].verified
			throw new Meteor.Error(400, "Mail already verified.")
		else
			Accounts.sendVerificationEmail user._id

			request.get { url: "https://www.gravatar.com/avatar/#{md5 user.emails[0].address}?d=identicon&d=404&s=1" }, Meteor.bindEnvironment (error, response) ->
				Meteor.users.update user._id, $set:
					gravatarUrl: "https://www.gravatar.com/avatar/#{md5 user.emails[0].address}?d=identicon&r=PG"
					hasGravatar: response.statusCode isnt 404

	mailExists: (mail) ->
		@unblock()
		Meteor.users.find(
			emails: {
				$elemMatch: {
					address: mail
				}
			}
		).count() isnt 0

	getUsersCount: ->
		@unblock()
		return Meteor.users.find().count()

	congratulate: ->
		return unless @userId? and Meteor.users.findOne(@userId).profile.birthDate.date() is Date.today()