###*
# @class Course
# @constructor
# @param {Date} from
# @param {Date} to
# @param {String} profile
# @param {String} userId
###
class @Course
	constructor: (@from, @to, @profile, @userId) ->
		###*
		# @property typeId
		# @type Number|undefined
		# @default undefined
		###
		@typeId = undefined

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

		###*
		# @property lastUpdated
		# @type Date|undefined
		# @default undefined
		###
		@lastUpdated = undefined

	###*
	# @method inside
	# @param {Date} date
	# @return {Boolean}
	###
	inside: (date) -> @from <= date <= @to

	@schema: new SimpleSchema
		from:
			type: Date
		to:
			type: Date
		profile:
			type: String
		userId:
			type: String
		typeId:
			type: null
			optional: yes
		externalId:
			type: null
			optional: yes
		fetchedBy:
			type: String
			optional: yes
