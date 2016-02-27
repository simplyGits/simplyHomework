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
	if Meteor.isServer
		g
	else
		g = _.extend new Grade(g.gradeStr), g
		_.extend g,
			__insufficient: if g.passed then '' else 'insufficient'

			# TODO: do this on a i18n friendly way.
			__grade: g.toString().replace '.', ','
			__weight: (
				if Math.floor(g.weight) is g.weight
					g.weight
				else
					g.weight.toFixed(1).replace '.', ','
			)

@StudyUtils = new Meteor.Collection 'studyUtils', transform: (su) -> _.extend new StudyUtil, su
@FileDownloadCounters  = new Mongo.Collection 'fileDownloadCounters'

@ScholierenClasses     = new Meteor.Collection 'scholieren.com'
@WoordjesLerenClasses  = new Meteor.Collection 'woordjesleren'
@Analytics             = new Meteor.Collection 'analytics'
@Tickets               = new Mongo.Collection 'tickets'
@Messages              = new Mongo.Collection 'messages', transform: (m) -> _.extend new Message, m
@Files = new Mongo.Collection 'files', transform: (f) -> _.extend new ExternalFile, f

Meteor.users._transform = (u) ->
	u.hasRole = (roles) -> userIsInRole u._id, roles
	u

Schemas.Classes = new SimpleSchema
	name:
		type: String
		label: 'Vaknaam'
		trim: yes
		regEx: /^[A-Z][^A-Z]+$/
	abbreviations:
		type: [String]
		label: 'Vakafkortingen'
	year:
		type: Number
	schoolVariant:
		type: String
		regEx: /^[a-z]+$/
	externalInfo:
		type: Object
		blackbox: yes

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
	description:
		type: String
		optional: yes
	deadline:
		type: Date
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

Schemas.Grades = new SimpleSchema
	grade:
		type: null
		custom: -> _.isNumber @value
	gradeStr:
		type: String
	gradeType:
		type: String
		allowedValues: [ 'number', 'percentage' ]
	weight:
		type: Number
		decimal: yes
		min: 0
	classId:
		type: String
		optional: yes # REVIEW
	ownerId:
		type: String
	description:
		type: String
		trim: yes
		optional: yes
	passed:
		type: Boolean
	isEnd:
		type: Boolean
	dateFilledIn:
		type: Date
	dateTestMade:
		type: Date
		optional: yes
	externalId:
		type: null
		optional: yes
	fetchedBy:
		type: String
		optional: yes
	period:
		type: null
		blackbox: yes
	###
	# TODO: This had problems because in magister-binding we're returning a stored
	# grade when it hasn't changed, this grade from the database doesn't have a
	# GradePeriod type but an object type thanks to how EJSON stringification.
	period:
		type: GradePeriod
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
	visibleFrom:
		type: Date
		optional: yes
		autoValue: ->
			if @isInsert and not @value? then new Date()
			else @value
	visibleTo:
		type: Date
		optional: yes
	fileIds:
		type: [String]
		defaultValue: []
	userIds:
		type: [String]
	fetchedBy:
		type: String
		optional: yes
	externalInfo:
		type: Object
		optional: yes
		blackbox: yes
	updatedOn:
		type: Date
		optional: yes
		autoValue: -> if @isInsert then undefined else new Date

Schemas.Absences = new SimpleSchema
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
	externalId:
		type: null # any type
		optional: yes
	fetchedBy:
		type: String
		optional: yes

Schemas.CalendarItems = new SimpleSchema
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

Schemas.Files = new SimpleSchema
	_id:
		type: String
	name:
		type: String
	userIds:
		type: [String]
	mime:
		type: String
	creationDate:
		type: Date
		optional: yes
	size:
		type: Number
	fetchedBy:
		type: String
		optional: yes
	externalId:
		type: null
		optional: yes
	downloadInfo:
		type: Object
		blackbox: yes

###
Schemas.Messages = new SimpleSchema
	subject:
		type: String
	body:
		type: String
	folder:
		type: String
		allowedValues: [ 'inbox', 'alerts', 'outbox' ]
	sendDate:
		type: Date
		index: -1
	sender:
		type: MessageRecipient
	recipients:
		type: [MessageRecipient]
	attachmentIds:
		type: [String]
		defaultValue: []
	fetchedFor:
		type: [String]
	readBy:
		type: [String]
	fetchedBy:
		type: String
		optional: yes
	externalId:
		type: null
		optional: yes
###

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
