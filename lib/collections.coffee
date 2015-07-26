@Schemas           = {}
@GoaledSchedules   = new Meteor.Collection 'goaledSchedules'
@Classes           = new Meteor.Collection 'classes'
@Books             = new Meteor.Collection 'books'
@Schools           = new Meteor.Collection 'schools'
@Schedules         = new Meteor.Collection 'schedules'
@Votes             = new Meteor.Collection 'votes'
@Utils             = new Meteor.Collection 'utils'
@Tickets           = new Meteor.Collection 'tickets'
@Projects          = new Meteor.Collection 'projects'
@CalendarItems     = new Meteor.Collection 'calendarItems', transform: (c) -> _.extend new CalendarItem, c
@ChatMessages      = new Meteor.Collection 'chatMessages'
@ReportItems       = new Meteor.Collection 'reportItems'
@StoredGrades      = new Meteor.Collection 'storedGrades', transform: (g) -> _.extend new StoredGrade, g
@StudyUtils        = new Meteor.Collection 'studyUtils',   transform: (s) -> _.extend new StudyUtil, s
@Notifications     = new Meteor.Collection 'notifications'

if Meteor.isClient
	@ScholierenClasses = new Meteor.Collection 'scholieren.com'

Schemas.Classes = new SimpleSchema
	_id:
		type: Meteor.Collection.ObjectID
	name:
		type: String
		label: "Vaknaam"
		trim: yes
		# TODO: Because of issues with some classes, the regex is disabled. Maybe we
		# can find another, better regex? Some weird names for classes are passed
		# through now.
		#regEx: /^[a-z ]+$/i
		index: 1
	abbreviations:
		type: [String]
		label: "Vakafkortingen"
		regEx: /^[\w&+-]*$/
	year:
		type: Number
	schoolVariant:
		type: String
		regEx: /^[a-z]+$/
	schedules:
		type: [Object]
		blackbox: yes
	scholierenClassId:
		type: Number
		optional: yes

Schemas.Books = new SimpleSchema
	_id:
		type: Meteor.Collection.ObjectID
	title:
		type: String
	publisher:
		type: String
		optional: yes
	scholierenBookId:
		type: Number
		optional: yes
	release:
		type: Number
		optional: yes
	classId:
		type: Meteor.Collection.ObjectID
	utils:
		type: [Object]
		blackbox: yes
	chapters:
		type: [Object]
		blackbox: yes

Schemas.Schools = new SimpleSchema
	_id:
		type: Meteor.Collection.ObjectID
	name:
		type: String
	url:
		type: String
		regEx: SimpleSchema.RegEx.Url
	externalId:
		type: null
		optional: yes
	fetchedBy:
		type: String
		optional: yes

Schemas.Projects = new SimpleSchema
	_id:
		type: Meteor.Collection.ObjectID
	name:
		type: String
		index: 1
	description:
		type: String
		optional: yes
	deadline:
		type: Date
		index: 1
	magisterId:
		type: Number
		optional: yes
	classId:
		type: Meteor.Collection.ObjectID
		optional: yes
	ownerId:
		type: String
		autoValue: ->
			if not @isFromTrustedCode and @isInsert
				@userId
			else @unset()
	participants:
		type: [String]
		autoValue: ->
			if not @isFromTrustedCode and @isInsert
				[@userId]
			else @unset()
	driveFileIds:
		type: [String]

Schemas.ChatMessages = new SimpleSchema
	_id:
		type: Meteor.Collection.ObjectID
	content:
		type: String
		autoValue: -> Helpers.convertLinksToAnchor @value
	creatorId:
		type: String
		index: 1
		autoValue: -> if not @isFromTrustedCode and @isInsert then @userId
		denyUpdate: yes
	time:
		type: Date
		index: -1
		autoValue: -> if @isInsert then new Date()
		denyUpdate: yes
	projectId:
		type: Meteor.Collection.ObjectID
		index: 1
		optional: yes
	groupId:
		type: Meteor.Collection.ObjectID
		index: 1
		optional: yes
	to:
		type: String
		index: 1
		optional: yes
	readBy:
		type: [String]
	attachments:
		type: [String]
	changedOn:
		type: Date
		optional: yes
		autoValue: ->
			if not @isFromTrustedCode and @isInsert then null

			# Force it to the change date when updating, we want to clearly show that an user changed a message.
			else if not @isFromTrustedCode and @isUpdate then new Date()

Schemas.GoaledSchedules = new SimpleSchema
	_id:
		type: Meteor.Collection.ObjectID
	ownerId:
		type: String
		index: 1
	dueDate:
		type: Date
	classId:
		type: Meteor.Collection.ObjectID
	createTime:
		type: Date
		autoValue: -> if @isInsert then new Date()
		denyUpdate: yes
	tasks:
		type: [Object]
		blackbox: yes
	magisterAppointmentId:
		type: Number
		optional: yes
	calendarItemId:
		type: Meteor.Collection.ObjectID
		optional: yes
	weight:
		type: Number
		optional: yes

Schemas.ReportItems = new SimpleSchema
	_id:
		type: Meteor.Collection.ObjectID
	userId:
		type: String
	reporterId:
		type: String
	reportGrounds:
		type: [String]
		minCount: 1
	time:
		type: Date

###
Schemas.StoredGrades = new SimpleSchema
	_id:
		type: Meteor.Collection.ObjectID
	grade:
		type: null
		custom: -> _.isNumber @value
		index: 1
	description:
		type: String
		defaultValue: ""
		trim: yes
	weight:
		# HACK: Number wasn't working, but should be used.
		#type: Number
		type: null
	dateFilledIn:
		type: Date
		index: 1
		optional: yes
	dateTestMade:
		type: Date
		index: 1
		optional: yes
	classId:
		type: Meteor.Collection.ObjectID
		# REVIEW: optional?
		optional: yes
	ownerId:
		type: String
	passed:
		type: Boolean
	isEnd:
		type: Boolean
		optional: yes
		index: 1
	externalId:
		type: null # any type.
		optional: yes
	fetchedBy:
		type: String
		optional: yes
	period:
		# TODO: make schema for `GradePeriod`
		type: null
###

Schemas.StudyUtils = new SimpleSchema
	_id:
		type: Meteor.Collection.ObjectID
	name:
		type: String
		trim: yes
	description:
		type: String
		trim: yes
		optional: yes
		defaultValue: ""
	classId:
		type: String
		# REVIEW: optional?
		optional: yes
	ownerId:
		type: String
	visibleFrom:
		type: Date
		optional: yes
		defaultValue: new Date()
	visibleTo:
		type: Date
		optional: yes
	files:
		type: [Object]
		blackbox: yes
		defaultValue: []
	fetchedBy:
		type: String
		optional: yes
	externalInfo:
		type: Object
		blackbox: yes
		optional: yes

@[key].attachSchema Schemas[key] for key of Schemas

@classTransform = (tmpClass) ->
	classInfo = -> _.find Meteor.user().classInfos, (cI) -> EJSON.equals cI.id, tmpClass._id
	groupInfo = _.find Meteor.user().profile.groupInfos, (gI) -> EJSON.equals gI.id, tmpClass._id

	_.extend tmpClass,
		__taskAmount: _.filter(homeworkItems.get(), (a) -> groupInfo?.group is a.description() and not a.isDone()).length
		__book: -> Books.findOne classInfo()?.bookId
		__color: -> classInfo()?.color
		__sidebarName: (
			val = tmpClass.name
			if val.length > 14 then tmpClass.abbreviations[0]
			else val
		)
		__showBadge: tmpClass.name.length not in [11..14]

		__classInfo: classInfo

@projectTransform = (p) ->
	return _.extend p,
		__class: -> Classes.findOne p.classId, transform: classTransform
		__borderColor: (
			if p.deadline < new Date then "#FF4136"
		)
		__friendlyDeadline: (
			if p.deadline?
				day = DayToDutch Helpers.weekDay p.deadline
				time = "#{Helpers.addZero p.deadline.getHours()}:#{Helpers.addZero p.deadline.getMinutes()}"

				date = switch Helpers.daysRange new Date, p.deadline, no
					when -6, -5, -4, -3 then "Afgelopen #{day}"
					when -2 then "Eergisteren"
					when -1 then "Gisteren"
					when 0 then "Vandaag"
					when 1 then "Morgen"
					when 2 then "Overmorgen"
					when 3, 4, 5, 6 then "Aanstaande #{day}"
					else "#{Helpers.cap day} #{DateToDutch p.deadline, no}"

				"#{date} #{time}"
		)
		__lastChatMessage: -> ChatMessages.findOne { projectId: p._id }, transform: chatMessageTransform, sort: "time": -1

chatMessageReplaceMap =
	":thumbsup:": [/\(y\)/ig]
	":thumbsdown:": [/\(n\)/ig]
	":innocent:": [/\(a\)/ig]
	":sunglasses:": [/\(h\)/ig]
	":sweat_smile:": [/\^\^'/ig]

###*
# Returns the given `date` friendly formatted for chat.
# If `date` is a null value, `null` will be returned.
#
# @method formatDate
# @param date {Date|null} The date to format.
# @return {String|null} The given `date` formatted.
###
formatDate = (date) ->
	return unless date?

	check date, Date
	m = moment date

	if m.year() isnt new Date().getUTCFullYear()
		m.format "DD-MM-YYYY HH:mm"
	else if m.toDate().date().getTime() isnt Date.today().getTime()
		m.format "DD-MM HH:mm"
	else
		m.format "HH:mm"


@chatMessageTransform = (cm) ->
	return _.extend cm,
		__sender: Meteor.users.findOne cm.creatorId
		__own: if Meteor.userId() is cm.creatorId then "own" else ""
		__time: formatDate cm.time
		content: (
			s = cm.content

			for key in _.keys chatMessageReplaceMap
				for regex in chatMessageReplaceMap[key]
					s = s.replace regex, key

			s
		)
		__changedOn: formatDate cm.changedOn
