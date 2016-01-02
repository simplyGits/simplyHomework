###*
# @class AbsenceInfo
# @constructor
# @param {String} userId The ID of the user this absence is of.
# @param {String} calendarItemId The ID of the calendar item this absence is for.
# @param {String} type The type of absence.
# @param {Boolean} permitted
###
class @AbsenceInfo
	constructor: (@userId, @calendarItemId, @type, @permitted) ->
		###*
		# @property description
		# @type string
		# @default ""
		###
		@description = ''
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
