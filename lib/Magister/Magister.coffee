class @Magister
	constructor: (@magisterSchool, @username, @password) ->
		@http = new MagisterHttp()
		@_reLogin()

	appointments: (from, to, callback) ->
		[from, to] = _.where arguments, (a) -> _.isDate a
		callback = _.find arguments, (a) -> _.isFunction a
		
		to ?= from

		@_forceReady()
		dateConvert = (date) -> "#{date.getUTCFullYear()}-#{_helpers.addZero(date.getMonth() + 1)}-#{_helpers.addZero(date.getDate())}"
		url = "#{@magisterSchool.url}/api/personen/#{@_id}/afspraken?tot=#{dateConvert(to)}&van=#{dateConvert(from)}"
		@http.get url, {},
			(error, result) =>
				result = EJSON.parse result.content
				if error?
					callback error, null
				else
					callback null, (Appointment._convertRaw(@, a) for a in result.Items)

	messageFolders: (query, callback) ->
		@_forceReady()
		callback = _.find(arguments, (a) -> _.isFunction a) ? (->)

		if _.isString(query) and query isnt ""
			result = _.where @_messageFolders, (mF) -> Helpers.contains mF.name, query, yes
		else
			result = @_messageFolders

		callback null, result
		return result

	inbox: (callback) -> callback ?= (->); @messageFolders("postvak in", (error, result) -> if error? then callback(error, null) else callback(null, result[0]))[0]
	sentItems: (callback) -> callback ?= (->); @messageFolders("verzonden items", (error, result) -> if error? then callback(error, null) else callback(null, result[0]))[0]
	bin: (callback) -> callback ?= (->); @messageFolders("verwijderde items", (error, result) -> if error? then callback(error, null) else callback(null, result[0]))[0]

	###*
	# Returns the profile for the current logged in user.
	#
	# @method profileInfo
	# @param callback {Function} The callback to give the error and result to.
	# @param raw {Boolean} If this is true the original response will only be parsed to a JS object and given back.
	# @return {ProfileInfo} The profile of the current logged in user.
	###
	profileInfo: (callback, raw = no) ->
		@_forceReady() unless raw
		@http.get "#{@magisterSchool.url}/api/account", {},
			(error, result) =>
				if error?
					callback error, null
				else
					callback null, unless raw then ProfileInfo._convertRaw(@, EJSON.parse result.content) else EJSON.parse result.content

	ready: (callback) ->
		if _.isFunction callback
			if @_ready
				callback @
			else
				@_readyCallbacks.push callback
		return @_ready is yes

	_forceReady: -> throw new Error "Not done with logging in! (use Magister.ready(callback) to be sure that logging in is done)" unless @_ready
	_setReady: ->
		@_ready = yes
		callback @ for callback in @_readyCallbacks
		@_readyCallbacks = []

	#_ticksLeft: 2
	#_tickReady = -> @_setReady() if --@_ticksLeft is 0

	_readyCallbacks: []

	_reLogin: ->
		url = "#{@magisterSchool.url}/api/sessie"
		@http.post url,
			Gebruikersnaam: @username
			Wachtwoord: @password
			GebruikersnaamOnthouden: yes
			IngelogdBlijven: yes
		, {headers: "Content-Type": "application/json;charset=UTF-8" }, (error, result) =>
			if error?
				throw new Error(error.message)
			else
				@_sessionId = /[a-z\d-]+/.exec(result.headers["set-cookie"][0])[0]
				@http._cookie = "SESSION_ID=#{@_sessionId}; M6UserName=#{@username}"
				@profileInfo ((error, result) =>
					@_group = result.Groep[0]
					@_id = result.Persoon.Id
					@_personUrl = "#{@magisterSchool.url}/api/personen/#{@_id}"

					@http.get "#{@magisterSchool.url}/api/personen/#{@_id}/berichten/mappen", {}, (error, result) =>
						@_messageFolders = (MessageFolder._convertRaw(@, m) for m in EJSON.parse(result.content).Items)
						@_setReady()
				), yes