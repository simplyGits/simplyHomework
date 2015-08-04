class @SchoolClass
	constructor: (name, course, @year, schoolVariant, scholierenClassId) ->
		###*
		# ID of class at Scholieren.com.
		# @property scholierenClassId
		# @type Number
		# @default null
		###

		@_id = new Meteor.Collection.ObjectID()

		@course = course?.toLowerCase() ? ""
		@schoolVariant = schoolVariant?.toLowerCase()
		@name = Helpers.cap name if name?

		@schedules = [] # Contains schedule ID's.
