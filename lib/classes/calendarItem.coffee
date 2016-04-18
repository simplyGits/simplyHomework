###*
# Item in the calendar.
#
# @class CalendarItem
# @param ownerId The ID of the creator of this CalendarItem.
# @param description {String} The description / content of this item.
# @param startDate {Date} The start date of this item.
# @param [endDate] {Date} The end date of this item. Defaults to 1 hour after `startDate`.
# @param [classId] If this item is linked with a class: the ID of the class; otherwise: undefined
# @constructor
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
		@endDate ?= moment(@startDate).add(1, "hour").toDate()

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
		# not something like: "every 20th day of the moth".
		#
		# The start of timing the interval is @startDate.
		# The end is set by @endDate.
		#
		# @property repeatInterval
		# @type Number
		# @default null
		###
		@repeatInterval = null

		###*
		# If this calendarItem is linked to an appointment
		# (eg for giving up homework that isn't filled in
		# into Magister, `externalId` will contain the
		# ID of the appointment this calendarItem is linked to.
		#
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

	relativeTime: (ignoreScrapped = no) ->
		return '' unless Meteor.isClient

		minuteTracker.depend()
		now = new Date
		diff = moment(@startDate).diff now

		if not moment(@startDate).isSame(now, 'day') or
		@fullDay or ( not ignoreScrapped and @scrapped )
			return ''

		if @startDate <= now <= @endDate
			"nog #{Helpers.timeDiff now, @endDate}"
		else if diff > 0
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
		externalId:
			type: null
			optional: yes
		fetchedBy:
			type: String
			optional: yes
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
