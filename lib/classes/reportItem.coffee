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
