###*
# @class Assignment
# @constructor
# @param name {String}
# @param classId {String}
# @param deadline {Date}
###
class @Assignment
	constructor: (@name, @classId, @deadline) ->
		###*
		# @property description
		# @type String|null
		# @default null
		###
		@description = null

		###*
		# Contains info about the people who handed this assignment in and when they
		# did that. Profile of each item in this array is:
		# { userId: <string>, on: <date> }
		#
		# @property handedInInfo
		# @type Object[]
		# @default []
		###
		@handedInInfo = []

		###*
		# @property externalId
		# @type mixed
		# @default null
		###
		@externalId = null

		###*
		# @property fetchedBy
		# @type String|null
		# @default null
		###
		@fetchedBy = null
