@Schemas         = {}
@GoaledSchedules = new Ground.Collection "goaledSchedules"
@Classes         = new Ground.Collection "classes"
@Books           = new Ground.Collection "books"
@Schools         = new Ground.Collection "schools"
@Schedules       = new Ground.Collection "schedules"
@Votes           = new Ground.Collection "votes"
@Utils           = new Ground.Collection "utils"
@Tickets         = new Ground.Collection "tickets"
@Projects        = new Ground.Collection "projects"
@CalendarItems   = new Meteor.Collection "calendarItems"
@ChatMessages    = new Ground.Collection "chatMessages"
#new Ground.Collection Meteor.users

@MagisterAppointments = new Ground.Collection "magisterAppointments",
	transform: (a) ->
		a._magisterObj = magister if magister?
		a._teachers = (_.extend(new Person, t) for t in a._teachers)

		a.__groupInfo = _.find Meteor.user()?.profile.groupInfos, (gi) -> gi.group is a._description
		a.__class = a.__groupInfo?.id
		a.__classInfo = _.find Meteor.user()?.classInfos, (ci) -> EJSON.equals ci.id, a.__class

		a._magisterObj = null
		return _.extend new Appointment, a
	sort: "_begin": 1

@MagisterStudyGuides = new Ground.Collection "magisterStudyGuides", transform: (s) ->
	s.parts = ( _.extend(new StudyGuidePart, part) for part in s.parts )
	p._files = (_.extend(new File, f) for f in p._files) for p in s.parts

	return _.extend new StudyGuide, s

@MagisterAssignments = new Ground.Collection "magisterAssignments", transform: (a) ->
	return _.extend new Assignment, a

@MagisterDigitalSchoolUtilties = new Ground.Collection "magisterDigitalSchoolUtilties", transform: (du) ->
	return _.extend new DigitalSchoolUtility, du

@ScholierenClasses = new Ground.Collection "scholieren.com"

Schemas.Classes = new SimpleSchema
	name:
		type: String
		label: "Vaknaam"
		trim: yes
		regEx: /^[a-z ]+$/i
		index: 1
	course:
		type: String
		label: "Vakafkorting"
		regEx: /^[a-z]+$/
	year:
		type: Number
	schoolVariant:
		type: String
		regEx: /^[a-z]+$/
	schedules:
		type: [Object]

Schemas.Books = new SimpleSchema
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
	chapters:
		type: [Object]

Schemas.Schools = new SimpleSchema
	name:
		type: String
	url:
		type: String
		regEx: /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/

Schemas.Projects = new SimpleSchema
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
	content:
		type: String
		denyUpdate: yes # Denying updates for now, later we can allow these with some UI implementations. (See the `isChanged` property)
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
	isChanged:
		type: Boolean
		autoValue: ->
			if not @isFromTrustedCode and @isInsert then no
			else if not @isFromTrustedCode and @isUpdate then yes # Force it to yes when updating, we want to clearly show that an user changed a message.

@[key].attachSchema Schemas[key] for key of Schemas

@classTransform = (tmpClass) ->
	classInfo = _.find Meteor.user().classInfos, (cI) -> EJSON.equals cI.id, tmpClass._id
	groupInfo = _.find Meteor.user().profile.groupInfos, (gI) -> EJSON.equals gI.id, tmpClass._id

	return _.extend tmpClass,
		__taskAmount: _.filter(homeworkItems.get(), (a) -> groupInfo?.group is a.description() and not a.isDone()).length
		__book: Books.findOne classInfo?.bookId
		__color: classInfo?.color
		__sidebarName: Helpers.cap if (val = tmpClass.name).length > 14 then tmpClass.course else val
		__showBadge: not _.contains [11..14], tmpClass.name.length

		__classInfo: classInfo

@projectTransform = (p) ->
	return _.extend p,
		__class: Classes.findOne p.classId, transform: classTransform
		__borderColor: (
			if p.deadline < new Date then "#FF4136"
		)
		__friendlyDeadline: (
			if p.deadline?
				day = DayToDutch Helpers.weekDay p.deadline
				time = "#{Helpers.addZero p.deadline.getHours()}:#{Helpers.addZero p.deadline.getMinutes()}"

				(switch Helpers.daysRange new Date(), p.deadline
					when -6, -5, -4, -3 then "Afgelopen #{day}"
					when -2 then "Eergisteren"
					when -1 then "Gisteren"
					when 0 then "Vandaag"
					when 1 then "Morgen"
					when 2 then "Overmorgen"
					when 3, 4, 5, 6 then "Aanstaande #{day}"
					else "#{Helpers.cap day} #{DateToDutch(p.deadline, no)}") + " " + time
		)
