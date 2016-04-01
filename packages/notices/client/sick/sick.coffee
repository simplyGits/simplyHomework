NoticeManager.provide 'sick', ->
	dateTracker.depend()
	lessons = ScheduleFunctions.lessonsForDate Meteor.userId(), new Date
	sick = _.any lessons, (item) ->
		info = item.getAbsenceInfo()
		not info? or
		info.type is 'sick' or
		/\bziek(te)?\b/i.test info.description
	if sick
		template: 'sick'
		header: "Beterschap #{Meteor.user().profile.firstName}!"
