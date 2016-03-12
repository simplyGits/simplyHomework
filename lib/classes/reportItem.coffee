###
# Item of an user reporting another user.
#
# @class ReportItem
# @param reporterId {String} The ID of the reporter.
# @param userId {String} The ID of the user that has been reported.
# @constructor
###
class @ReportItem
	constructor: (@reporterId, @userId) ->
		###*
		# For what the user has reported this time.
		# @property reportGrounds
		# @type String[]
		# @default []
		###
		@reportGrounds = []

		###*
		# The time this report has been inserted.
		# @property time
		# @type Date
		# @final
		# @default new Date()
		###
		@time = new Date()

		###*
		# Object containing the info about the resolvement of this item.
		# @property resolvedInfo
		# @type Object|undefined
		# @default undefined
		###
		@resolvedInfo = undefined

	@schema: new SimpleSchema
		reporterId:
			type: String
		userId:
			type: String
		reportGrounds:
			type: [String]
			minCount: 1
		time:
			type: Date
			autoValue: -> if @isInsert then new Date()
			denyUpdate: yes

		resolvedInfo:
			type: Object
			optional: yes
		'resolvedInfo.by'
			type: String
		'resolvedInfo.at'
			type: Date

@ReportItems = new Meteor.Collection 'reportItems'
@ReportItems.attachSchema ReportItem.schema
