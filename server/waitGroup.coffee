Future = require 'fibers/future'

class @WaitGroup
	constructor: ->
		@_futs = []

	_getFuture: ->
		fut = new Future
		@_futs.push fut
		fut

	add: (cb) ->
		fut = @_getFuture()
		fut.resolver()

	defer: (fn) ->
		fut = @_getFuture()
		Meteor.defer ->
			fut.return fn()

	wait: ->
		fut.wait() for fut in @_futs
