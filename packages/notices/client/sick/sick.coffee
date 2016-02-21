NoticeManager.provide 'sick', ->
	dateTracker.depend()
	lessons = ScheduleFunctions.lessonsForDate Meteor.userId(), new Date
	sick = _.any lessons, (item) -> item.getAbsenceInfo()?.description is 'Ziekte'
	if sick
		template: 'sick'
		header: "Beterschap #{Meteor.user().profile.firstName}!"
