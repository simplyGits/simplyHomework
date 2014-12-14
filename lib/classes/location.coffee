root = @

###*
# A location
# Currently not reactive, we will see how it goes.
#
# @class Location
###
class @Location
	constructor: (@_parent) ->
		@location = ""

	@_match: (location) ->
		return Match.test location, Match.OneOf(
			Match.ObjectIncluding(
					longitude: Number
					latitude: Number
					
			), Match.ObjectIncluding(
					location: String
			))