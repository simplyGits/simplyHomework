###*
# Factory for the top level/collection classes, allows for automatic updating if a class is changed.
# The changes of the classes floats up, until they reach the beginning (the factory)
# There it will automatically update the correct Meteor.collection.
#
# Call each method with New.[name of class (without caps)]([params of the constructor of the class])
#
# @variable New
###
@New =
	schedular: (params...) ->
		throw new WrongPlatformException("Schedular is only settable from the client") unless Meteor.isClient

		schedular = new Schedular null, params...
		Meteor.users.update Meteor.userId(), $set: { schedular }
		return _decodeObject schedular

@Get = # required for serverside, also has additions for some client side shit.
	schedular: -> if !Meteor.user().schedular? then null else _setDeps.schedular _decodeObject Meteor.user().schedular
	
	classes: (query = {}, options = {}) =>
		if Meteor.isServer
			Classes.find query, _.extend options, transform: (c) => @_decodeObject c
		else
			Classes.find query, options
	goaledSchedules: (query = {}, options = {}) =>
		if Meteor.isServer
			GoaledSchedules.find query, _.extend options, transform: (gs) => @_decodeObject gs
		else
			GoaledSchedules.find query, options
	schools: (query = {}, options = {}) =>
		if Meteor.isServer
			Schools.find query, _.extend options, transform: (s) => @_decodeObject s
		else
			Schools.find query, options
	projects: (query = {}, options = {}) =>
		if Meteor.isServer
			Projects.find query, _.extend options, transform: (p) => @_decodeObject p
		else
			Projects.find query, options

@_decodeObject = (val, sender) ->
	if _.isObject val
		readyVal = val

		if val._className? and !val._parent?
			readyVal._parent = sender           		 # fix sender
			newInstance = new @[val._className]() 		 # create new instance of same class
			readyVal = uS.defaults val, newInstance		 # copy all the other missing parts
			readyVal.constructor = @[val._className]     # Fix the constructor for nicer debugging <3

		for key in _.keys val
			value = val[key]

			readyVal[key] = (_decodeObject(item, readyVal) for item in value) if _.isArray(value)
			readyVal[key] = _decodeObject(value, readyVal) if key isnt "_parent" and key isnt "dependency"
		
		return readyVal

	else if _.isArray val then return (_decodeObject(item, sender) for item in val)
		
	else return val