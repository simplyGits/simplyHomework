###*
# Item in the calendar.
#
# @class CalendarItem
# @constructor
# @param {String} ownerId The ID of the creator of this CalendarItem.
# @param {String} description The description this calendarItem.
# @param {Date} startDate The start date of this item.
# @param {Date} [endDate] The end date of this item. Defaults to 1 hour after `startDate`.
# @param {String} [classId] This ID of the Class this calendarItem is linked with.
###
class @CalendarItem
	# TODO: Better i18n for these methods?
	@contentTypeLong: (contentType) ->
		switch contentType
			when 'homework' then 'Huiswerk'
			when 'test' then 'Proefwerk'
			when 'exam' then 'Examen'
			when 'quiz' then 'Schriftelijke Overhoring'
			when 'oral' then 'Mondelinge Overhoring'
			when 'information' then 'Informatie'

			else 'Inhoud'

	constructor: (ownerId, @description, @startDate, @endDate, @classId) ->
		@_id = new Mongo.ObjectID().toHexString()
		@endDate ?= moment(@startDate).add(1, 'hour').toDate()

		###*
		# @property userIds
		# @type String[]
		# @default [ ownerId ]
		###
		@userIds = [ ownerId ]

		###*
		# @property usersDone
		# @type String[]
		# @defualt []
		###
		@usersDone = []

		###*
		# @property content
		# @type Object|null
		# @default null
		###
		@content = null

		###*
		# The interval for repeating in seconds.
		# If null, this CalendarItem doesn't repeat.
		# Warning: This method only supports 'dumb' repeats,
		# not something like: 'every 20th day of the month'.
		#
		# The start of timing the interval is @startDate.
		# The end is set by @endDate.
		#
		# @property repeatInterval
		# @type Number
		# @default null
		###
		@repeatInterval = null

		# TODO: update the calendarItem upstream when the item has been changed and
		# this option is true.

		###*
		# `ExternalInfos` will contain info about this calendarItem on a service
		# paired with the service's name.
		#
		# A service can store arbitrary information in the key. The manage is fully
		# responsible for using and providing the data.
		#
		# @property externalInfos
		# @type Object
		# @default {}
		###
		@externalInfos = {}

		###*
		# @property scrapped
		# @type Boolean
		# @defualt false
		###
		@scrapped = no

		###*
		# @property fullDay
		# @type Boolean
		# @default false
		###
		@fullDay = no

		###*
		# @property schoolHour
		# @type Number|null
		# @default null
		###
		@schoolHour = null

		###*
		# @property location
		# @type String|null
		# @default null
		###
		@location = null

		###*
		# @property teacher
		# @type Object|null
		# @default null
		###
		@teacher = null

		###*
		# @property type
		# @type String|undefined
		# @default undefined
		###
		@type = undefined

		###*
		# @property fileIds
		# @type String[]
		# @default []
		###
		@fileIds = []

	###*
	# @method class
	# @return {SchoolClass}
	###
	class: -> Classes.findOne @classId
	###*
	# @method getAbsenceInfo
	# @param {String} [userId=Meteor.userId()]
	# @return {AbsenceInfo}
	###
	getAbsenceInfo: (userId = Meteor.userId()) ->
		Absences.findOne
			userId: userId
			calendarItemId: @_id

	contentTypeLong: -> CalendarItem.contentTypeLong @content?.type

	contentTypeShort: ->
		switch @content?.type
			when 'homework' then 'HW'
			when 'test' then 'PW'
			when 'exam' then 'TT'
			when 'quiz' then 'SO'
			when 'oral' then 'LT'
			when 'information' then 'INF'

			else '??'

	relativeTime: (showForScrapped = no) ->
		return '' unless Meteor.isClient

		minuteTracker.depend()
		now = new Date
		m = moment @startDate

		if not m.isSame(now, 'day') or
		@fullDay or (not showForScrapped and @scrapped)
			return ''

		if @startDate <= now <= @endDate
			"nog #{Helpers.timeDiff now, @endDate}"
		else if now < @startDate
			"over #{Helpers.timeDiff now, @startDate}"
		else
			"#{Helpers.timeDiff now, @endDate} geleden"

	group: ->
		if @description?
			_.find @description.split(' '), (w) -> /\d/.test(w) and /[a-z]/i.test(w)

	files: -> Files.find(_id: $in: @fileIds).fetch()

	@schema: new SimpleSchema
		userIds:
			type: [String]
		description:
			type: String
		startDate:
			type: Date
		endDate:
			type: Date
		classId:
			type: String
			optional: yes
		usersDone:
			type: [String]
		content:
			type: Object
			optional: yes
			blackbox: yes
		repeatInterval:
			type: Number
			optional: yes
		externalInfos:
			type: Object
			blackbox: yes
		scrapped:
			type: Boolean
		fullDay:
			type: Boolean
		schoolHour:
			type: Number
			optional: yes
		location:
			type: String
			optional: yes
		teacher:
			type: Object
			optional: yes
			blackbox: yes
		type:
			type: String
			optional: yes
		fileIds:
			type: [String]
			defaultValue: []
		updateInfo:
			type: Object
			blackbox: yes
			optional: yes

@CalendarItems = new Mongo.Collection 'calendarItems', transform: (c) -> _.extend new CalendarItem, c
@CalendarItems.attachSchema CalendarItem.schema
