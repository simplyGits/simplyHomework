_superStronkCache = amplify?.store?("superStronkCache_#{Meteor.userId()}") ? {}

superStronkCache = (key, value) ->
	if value?
		_superStronkCache[key] = value
		amplify?.store? "superStronkCache_#{Meteor.userId()}", _superStronkCache, expires: 259200000

	return _superStronkCache[key]

class @MagisterHttp
	###
	# HTTP CLASS
	# ======================
	#
	# You have to implement this with your own serverside implementation.
	# Beneath here are the requirements you have to follow.
	#
	# ======================
	#  MINIMAL REQUIREMENTS
	# ======================
	# callback: function (error, result) {...}
	# result: { content (string), headers (dictionary) }
	# options: { headers (dictionary), data (object) }
	#
	# get(url, options*, callback)
	# delete(url, options*, callback)
	# post(url, data, options*, callback)
	# put(url, data, options*, callback)
	#
	# * = optional (Fill with default value if null (object) ex.: options ?= {})
	#
	# Class holds variable _cookie which is required to be added to the headers
	#
	# =======================
	#  METEOR IMPLEMENTATION
	# =======================
	###
	get: (url, options = {}, callback) ->
		if not Meteor.status? or Meteor.status().connected
			Meteor.call "http", "GET", url, @_cookieInserter(options), (e, r) -> callback(e, r); superStronkCache(url, r) unless e?
		else callback null, superStronkCache url

	delete: (url, options = {}, callback) ->
		if not Meteor.status? or Meteor.status().connected
			Meteor.call "http", "DELETE", url, @_cookieInserter(options), (e, r) -> callback(e, r); superStronkCache(url, r) unless e?
		else callback null, superStronkCache url

	post: (url, data, options = {}, callback) ->
		if not Meteor.status? or Meteor.status().connected
			Meteor.call "http", "POST", url, @_cookieInserter(_.extend({data}, options)), (e, r) -> callback(e, r); superStronkCache(url, r) unless e?
		else callback null, superStronkCache url

	put: (url, data, options = {}, callback) ->
		if not Meteor.status? or Meteor.status().connected
			Meteor.call "http", "PUT", url, @_cookieInserter(_.extend({data}, options)), (e, r) -> callback(e, r); superStronkCache(url, r) unless e?
		else callback null, superStronkCache url

	_cookie: ""
	_cookieInserter: (original) ->
		original ?= {}
		original.headers = if @_cookie isnt "" then _.extend (original.headers ? {}), { cookie: @_cookie } else original.headers ? {}
		return original
###
	================
	 jQuery Example
	================

	get: (url, options = {}, callback) ->
		$
			.get url, options, (r) -> callback null, { content: r }
			.fail (e) -> callback e, null
###
