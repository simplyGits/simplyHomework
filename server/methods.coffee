Meteor.methods
	http: (method, url, options = {}) ->
		options.headers = _.extend (options.headers ? {}), "User-Agent": "simplyHomework"

		console.log "-----"
		if @userId?
			console.log "#{method} (by #{Meteor.users.findOne(@userId).emails[0].address})"
		else
			console.log method
		console.log url
		console.log options
		try
			return HTTP.call method, url, options
		catch e
			console.log "ERROR ======"
			console.log e
			throw new Meteor.Error 500, "Error 500: Internal server error", "error while calling HTTP.call: #{e.name} | #{e.message} | #{e.stack}"
	
	log: (type, message, elements...) -> console[type] message, elements...

	setMagisterInfo: (info) ->
		userId = @userId
		{ username, password } = info.magisterCredentials
		info.school.url = "https://#{info.school.url}"
		try
			HTTP.post "#{info.school.url}/api/sessie",
				data:
					"Gebruikersnaam": username
					"Wachtwoord": password
					"IngelogdBlijven": no
				headers:
					"Content-Type": "application/json;charset=UTF-8"

			new Magister(info.school, username, password).ready (m) ->
				m.http.get m.profileInfo().profilePicture(200, 200, yes), {}, (e, r) ->
					return if e?
					# base64 = null
					# try
					# 	base64 = CryptoJS.enc.Base64.stringify r.content
					# catch
					# 	console.log "catched."

					Meteor.users.update userId,
						$set:
							magisterCredentials: info.magisterCredentials
							"profile.schoolId": info.schoolId
							# "profile.magisterPicture": base64
							"profile.birthDate": m.profileInfo().birthDate()
			return yes
		catch
			return no

	changeMail: (mail) ->
		Meteor.users.update @userId, $set: { "emails": [ { address: mail, verified: no } ] }
		Meteor.call "verifyMail"

	verifyMail: (username) ->
		user = if username? then Meteor.users.findOne {username} else Meteor.users.findOne @userId

		if user.emails[0].verified
			throw new Meteor.Error(400, "Mail already verified.")
		else
			Accounts.sendVerificationEmail user._id
			Meteor.users.update user._id, $set: gravatarUrl: "https://www.gravatar.com/avatar/#{md5 user.emails[0].address}?d=identicon&r=PG"

	mailExists: (mail) ->
		Meteor.users.find(
			emails: {
				$elemMatch: {
					address: mail
				}
			}
		).count() isnt 0

	execute: (command, useCoffee = yes) ->
		throw new Meteor.Error 401, "You're not an admin!" unless AuthManager.userIsInRole @userId, ["admin"]
		
		try
			result = if useCoffee then CoffeeScript.eval(command) else eval(command)
			return EJSON.stringify { command, result }
		catch e
			throw new Meteor.Error "500", e.message

	getGravatar: (userId, size = 50) -> "https://www.gravatar.com/avatar/#{md5 Meteor.users.findOne(userId).emails[0].address}?s=#{size}&d=identicon&r=PG"

	congratulate: ->
		
