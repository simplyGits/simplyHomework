###*
# Repesents a school.
#
# @class School
###
class @School
	###*
	# Constructor for the current School
	#
	# @method constructor
	# @param name {String} The name of the school
	# @param [url] {String} The URL of the school.
	###
	constructor: (@name, @url) ->
		###*
		# @property externalInfo
		# @type Object
		# @default {}
		###
		@externalInfo = {}

	###*
	# Return a cursor pointing to the users that that are pupils of this school.
	#
	# @method users
	# @return {Cursor} A cursor pointing to the users that are pupils of this school.
	###
	users: -> Meteor.users.find 'profile.schoolId': @_id

	@schema: new SimpleSchema
		name:
			type: String
		url:
			type: String
			regEx: SimpleSchema.RegEx.Url
			optional: yes
		externalInfo:
			type: Object
			blackbox: yes

@Schools = new Meteor.Collection 'schools', transform: (s) -> _.extend new School, s
@Schools.attachSchema School.schema
