@Schemas               = {}
@Classes               = new Meteor.Collection 'classes', transform: (c) -> classTransform c
@Books                 = new Meteor.Collection 'books'
@Schools               = new Meteor.Collection 'schools', transform: (s) -> _.extend new School, s
@Schedules             = new Meteor.Collection 'schedules'
@Utils                 = new Meteor.Collection 'utils'
@Projects              = new Meteor.Collection 'projects', transform: (p) -> projectTransform p
@Absences              = new Meteor.Collection 'absences'
@CalendarItems         = new Meteor.Collection 'calendarItems', transform: (c) -> _.extend new CalendarItem, c
@ReportItems           = new Meteor.Collection 'reportItems'
@Grades                = new Meteor.Collection 'grades', transform: (g) ->
	g = _.extend new Grade(g.gradeStr), g
	_.extend g,
		__insufficient: if g.passed then '' else 'insufficient'
		# TODO: do this on a i18n friendly way.
		__grade: g.toString().replace '.', ','

@StudyUtils            = new Meteor.Collection 'studyUtils',   transform: (s) -> _.extend new StudyUtil, s
@ScholierenClasses     = new Meteor.Collection 'scholieren.com'
@WoordjesLerenClasses  = new Meteor.Collection 'woordjesleren'
@Analytics             = new Meteor.Collection 'analytics'
@Tickets               = new Mongo.Collection 'tickets'

Meteor.users._transform = (u) ->
	u.hasRole = (roles) -> userIsInRole u._id, roles
	u

###
Schemas.Classes = new SimpleSchema
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
		index: 1
	schoolVariant:
		type: String
		index: 1
		regEx: /^[a-z]+$/
	schedules:
		type: [Object]
		blackbox: yes
	externalInfo:
		type: Object
		blackbox: yes
###

Schemas.Books = new SimpleSchema
	title:
		type: String
	classId:
		type: String
	publisher:
		type: String
		optional: yes
	release:
		type: Number
		optional: yes
	utils:
		type: [Object]
		blackbox: yes
	externalInfo:
		type: Object
		blackbox: yes

Schemas.Schools = new SimpleSchema
	name:
		type: String
	url:
		type: String
		regEx: SimpleSchema.RegEx.Url
		optional: yes
	externalInfo:
		type: Object
		blackbox: yes

Schemas.Projects = new SimpleSchema
	name:
		type: String
		autoValue: ->
			# Remove emojis.
			@value.replace /[\uD83C-\uDBFF\uDC00-\uDFFF]+/g, '' if @value?
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
		type: String
		optional: yes
	creatorId:
		type: String
		denyUpdate: yes
		autoValue: -> if not @isFromTrustedCode and @isInsert then @userId else @value
	participants:
		type: [String]
		index: 1
		autoValue: ->
			if not @isFromTrustedCode and @isInsert
				[@userId]
			else @value
	driveFileIds:
		type: [String]
	finished:
		type: Boolean
		autoValue: ->
			if not @isFromTrustedCode and @isInsert then no
			else @value

Schemas.ReportItems = new SimpleSchema
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

###
Schemas.Grades = new SimpleSchema
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
		type: String
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

Schemas.Absences = new SimpleSchema
	userId:
		type: String
		index: 1
	calendarItemId:
		type: String
		index: 1
	type:
		type: String
		# TODO: fill in allowedValues
		#allowedValues: ['']
	permitted:
		type: Boolean
	description:
		type: String
	externalId:
		type: null # any type
		optional: yes
	fetchedBy:
		type: String
		optional: yes

@[key].attachSchema Schemas[key] for key of Schemas

@classTransform = (c) ->
	return c if Meteor.isServer
	classInfo = _.find getClassInfos(), (info) -> EJSON.equals info.id, c._id

	_.extend c,
		#__taskAmount: _.filter(homeworkItems.get(), (a) -> groupInfo?.group is a.description() and not a.isDone()).length
		__book: -> Books.findOne classInfo?.bookId
		__sidebarName: (
			val = c.name
			if val.length > 14 then c.abbreviations[0]
			else val
		)

		__color: classInfo?.color
		__classInfo: classInfo

@projectTransform = (p) ->
	_.extend p,
		__class: -> Classes.findOne p.classId, transform: classTransform
		__borderColor: (
			now = new Date
			if p.deadline?
				switch
					when p.deadline < now then '#FF4136'
					when Helpers.daysRange(now, p.deadline, no) < 2 then '#FF8D00'
					else '#2ECC40'
			else
				'#000'
		)
		__friendlyDeadline: (
			if p.deadline?
				Helpers.cap Helpers.formatDateRelative p.deadline, yes
		)
		__chatRoom: -> ChatRooms.findOne projectId: p._id
		__lastChatMessage: ->
			chatRoom = @__chatRoom()
			if chatRoom?
				ChatMessages.findOne {
					chatRoomId: chatRoom._id
				}, sort:
					'time': -1
