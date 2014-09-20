Meteor.methods
	http: (method, url, options) ->
		options ?= {}
		options.headers = _.extend (options?.headers ? {}), "User-Agent": "simplyHomework"

		console.log "-----"
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
		try
			HTTP.post("https://mata-#{info.url}/api/sessie", data: { "Gebruikersnaam": info.magisterCredentials.username, "Wachtwoord": info.magisterCredentials.password })
		catch
			return false
		Meteor.users.update @userId,
			$set:
				magisterCredentials: info.magisterCredentials
				"profile.schoolId": info.schoolId
		return true

	verifyMail: (username) ->
		user = if username? then Meteor.users.findOne {username} else Meteor.users.findOne @userId

		if user.emails[0].verified
			new Meteor.Error(400, "Mail already verified.")
		else
			Accounts.sendVerificationEmail user._id
			Meteor.users.update user._id, $set: gravatarUrl: "https://www.gravatar.com/avatar/#{md5 user.emails[0].address}?s=100&d=identicon&r=PG"

	mailExists: (mail) ->
		Meteor.users.find(
			emails: {
				$elemMatch: {
					address: mail
				}
			}
		).count() isnt 0

	execute: (command, useCoffee = yes) ->
		throw new Meteor.Error 405, "You're not an admin!" unless AuthManager.userIsInRole @userId, ["admin"]
		
		try
			result = if useCoffee then CoffeeScript.eval(command) else eval(command)
			return EJSON.stringify { command, result }
		catch e
			throw new Meteor.Error "500", e.message

	getGravatar: (userId, size = 50) -> "https://www.gravatar.com/avatar/#{md5 Meteor.users.findOne(userId).emails[0].address}?s=#{size}&d=identicon&r=PG"

	congratulate: ->
		