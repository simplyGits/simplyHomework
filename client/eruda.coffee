if Meteor.isDevelopment and Helpers.isPhone()
	eruda = require 'eruda'

	Meteor.startup ->
			eruda.init()
