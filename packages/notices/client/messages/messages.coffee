recentMessages = ->
	dateTracker.depend()
	date = Date.today().addDays -5
	Messages.find({
		sendDate: $gte: date
		readBy: $ne: Meteor.userId()
	}, {
		sort:
			sendDate: -1
	}).fetch()

NoticeManager.provide 'messges', ->
	@subscribe 'messages', 0, [ 'inbox' ], yes

	if recentMessages().length
		template: 'unreadMessages'
		header: 'Ongelezen berichten'
		priority: 0

Template.unreadMessages.helpers
	messages: -> recentMessages()
