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
		# @property externalInfo
		# @type Object
		# @default {}
		###
		@externalInfo = {}
		###*
		# @property fetchedBy
		# @type String|undefined
		# @default undefined
		###
		@fetchedBy = undefined

	@schema: new SimpleSchema
		userId:
			type: String
		calendarItemId:
			type: String
		type:
			type: String
			# TODO: fill in allowedValues
			#allowedValues: ['']
		permitted:
			type: Boolean
		description:
			type: String
		externalInfo:
			type: Object
			blackbox: yes
		fetchedBy:
			type: String
			optional: yes

@Absences = new Mongo.Collection 'absences'
@Absences.attachSchema AbsenceInfo.schema
