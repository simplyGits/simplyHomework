###*
# @class SchoolClass
# @constructor
# @param name {String}
# @param abbreviation {String}
# @param year {Number} The year of the class this class is in.
# @param schoolVariant {String} e.g VWO
###
class @SchoolClass
	constructor: (name, abbreviation, @year, @schoolVariant) ->
		@_id = new Meteor.Collection.ObjectID

		@name = Helpers.cap name if name?
		@schoolVariant = @schoolVariant?.toLowerCase()
		abbreviation = abbreviation.toLowerCase().trim()

		###*
		# @property abbreviations
		# @type String[]
		###
		@abbreviations = []
		@abbreviations.push abbreviation unless _.isEmpty abbreviation

		@schedules = [] # Contains schedule ID's.

		###*
		# ID of class at Scholieren.com.
		# @property scholierenClassId
		# @type Number
		# @default undefined
		###
		@scholierenClassId = undefined
