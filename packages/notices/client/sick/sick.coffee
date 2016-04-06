NoticeManager.provide 'sick', ->
	dateTracker.depend()
	lessons = ScheduleFunctions.lessonsForDate Meteor.userId(), new Date
	sick = _.any lessons, (item) ->
		info = item.getAbsenceInfo()
		info? and (
			info.type is 'sick' or
			/\bziek(te)?\b/i.test info.description
		)
	if sick
		header: "Beterschap #{Meteor.user().profile.firstName}!"
