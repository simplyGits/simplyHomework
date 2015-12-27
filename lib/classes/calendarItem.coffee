###*
# Item in the calendar.
#
# @class CalendarItem
# @param ownerId The ID of the creator of this CalendarItem.
# @param description {String} The description / content of this item.
# @param startDate {Date} The start date of this item.
# @param [endDate] {Date} The end date of this item.
# @param [classId] If this item is linked with a class: the ID of the class; otherwise: null
# @constructor
###
class @CalendarItem
	constructor: (ownerId, @description, @startDate, @endDate, @classId) ->
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
		# @default null
		###
		@externalId = null

		###*
		# @property fetchedBy
		# @type String|null
		# @default null
		###
		@fetchedBy = null

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
	# @method class
	# @return {SchoolClass}
	###
	class: -> Classes.findOne @classId, transform: classTransform
	###*
	# @method getAbsenceInfo
	# @param {String} userId
	# @return {AbsenceInfo}
	###
	getAbsenceInfo: (userId) ->
		Absences.findOne
			userId: Meteor.userId()
			calendarItemId: @_id

	# TODO: Better i18n for these methods?
	contentTypeLong: ->
		switch @content?.type
			when 'homework' then 'Huiswerk'
			when 'test' then 'Proefwerk'
			when 'exam' then 'Examen'
			when 'quiz' then 'Schrijftelijke Overhoring'
			when 'oral' then 'Mondlinge Overhoring'
			when 'information' then 'Informatie'

			else 'Inhoud'

	contentTypeShort: ->
		switch @content?.type
			when 'homework' then 'HW'
			when 'test' then 'PW'
			when 'exam' then 'TT'
			when 'quiz' then 'SO'
			when 'oral' then 'LT'
			when 'information' then 'IN'

			else '??'

	relativeTime: ->
		return '' unless Meteor.isClient

		minuteTracker.depend()
		now = new Date
		diff = moment(@startDate).diff now

		unless moment(@startDate).isSame(now, 'day') and
		not @fullDay and
		not @scrapped
			return ''

		if @startDate <= now <= @endDate
			"nog #{Helpers.timeDiff now, @endDate}"
		else if diff > 0
			"over #{Helpers.timeDiff now, @startDate}"
		else
			"#{Helpers.timeDiff now, @endDate} geleden"
