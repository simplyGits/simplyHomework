recentMessages = ->
	dateTracker.depend()
	date = Date.today().addDays -5
	Messages.find({
		sendDate: $gte: date
		isRead: no
	}, {
		sort:
			sendDate: -1
	}).fetch()

NoticeManager.provide 'messages', ->
	@subscribe 'messages', 0, [ 'inbox' ], yes

	if recentMessages().length
		template: 'unreadMessages'
		header: 'Ongelezen berichten'
		priority: 0

Template.unreadMessages.helpers
	messages: -> recentMessages()
