class @MagisterHttp
	###
	# METEOR IMPLEMENTATION
	# =====================
	#
	# callback: function (error, result) {...}
	#
	# get(url, options, callback)
	# remove(url, options, callback)
	# post(url, data, options, callback)
	###
	get: (url, options = {}, callback = ->) -> Meteor.call "http", "GET", url, @_cookieInserter(options), callback
	remove: (url, options = {}, callback = ->) -> Meteor.call "http", "REMOVE", url, @_cookieInserter(options), callback
	post: (url, data, options = {}, callback = ->) -> Meteor.call "http", "POST", url, @_cookieInserter(_.extend({data}, options)), callback
	put: (url, data, options = {}, callback = ->) -> Meteor.call "http", "PUT", url, @_cookieInserter(_.extend({data}, options)), callback

	_cookie: ""
	_cookieInserter: (original) ->
		original ?= {}
		original.headers = if @_cookie isnt "" then _.extend (original.headers ? {}), { cookie: @_cookie } else original.headers ? {}
		return original