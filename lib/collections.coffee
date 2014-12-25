@GoaledSchedules = new Meteor.Collection "goaledSchedules"
@Classes         = new Meteor.Collection "classes"
@Books           = new Meteor.Collection "books"
@Schools         = new Meteor.Collection "schools"
@Schedules       = new Meteor.Collection "schedules"
@Votes           = new Meteor.Collection "votes"
@Utils           = new Meteor.Collection "utils"
@Tickets         = new Meteor.Collection "tickets"
@Projects        = new Meteor.Collection "projects"
@CalendarItems   = new Meteor.Collection "calendarItems"

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