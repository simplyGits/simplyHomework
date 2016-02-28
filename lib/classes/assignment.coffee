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
		# @type String|undefined
		# @default undefined
		###
		@description = undefined

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
		# @default undefined
		###
		@externalId = undefined

		###*
		# @property fetchedBy
		# @type String|undefined
		# @default undefined
		###
		@fetchedBy = undefined
