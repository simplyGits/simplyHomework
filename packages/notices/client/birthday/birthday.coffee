NoticeManager.provide 'birthday', ->
	dateTracker.depend()
	birthDate = getUserField Meteor.userId(), 'profile.birthDate'

	if birthDate? and Helpers.datesEqual(new Date, birthDate)
		template: 'birthday'
		priority: 2
