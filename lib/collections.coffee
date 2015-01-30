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
@CalendarItems   = new Ground.Collection "calendarItems"
@ChatMessages    = new Ground.Collection "chatMessages"

Schemas.Classes = new SimpleSchema
	name:
		type: String
		label: "Vaknaam"
		regEx: /^[A-Z][a-z]+$/
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
	woordjesLerenBookId:
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

@[key].attachSchema Schemas[key] for key of Schemas

@classTransform = (tmpClass) ->
	return _.extend tmpClass,
		__taskAmount: _.filter(homeworkItems.get(), (a) -> Meteor.user().profile.groupInfos.smartFind(tmpClass._id, (i) -> i.id)?.group is a.description() and not a.isDone()).length#Helpers.getTotal _.reject(GoaledSchedules.find(_homework: { $exists: true }, ownerId: Meteor.userId()).fetch(), (gS) -> !EJSON.equals(gS.classId(), tmpClass._id)), (gS) -> gS.tasksForToday().length
		__color: Meteor.user().classInfos.smartFind(tmpClass._id, (cI) -> cI.id).color
		__book: Books.findOne Meteor.user().classInfos.smartFind(tmpClass._id, (cI) -> cI.id).bookId
		__sidebarName: Helpers.cap if (val = tmpClass.name).length > 14 then tmpClass.course else val
		__showBadge: not _.contains [11..14], tmpClass.name.length

		__classInfo: _.find Meteor.user().classInfos, (c) -> EJSON.equals c.id, tmpClass._id

@projectTransform = (p) ->
	return _.extend p,
		__class: Classes.findOne(p.classId, transform: classTransform)
