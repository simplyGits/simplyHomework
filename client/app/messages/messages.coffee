# HACK

currentFolder = -> FlowRouter.getParam 'folder'

setCurrentMessage = (id) -> FlowRouter.setParams message: id
currentMessage = -> _.find messages.get(), _id: +FlowRouter.getParam('message')

composing = -> FlowRouter.getRouteName() is 'composeMessage'

@messages = messages = ReactiveVar []
isLoading = new ReactiveVar yes
hasMagister = new ReactiveVar yes
amount = new ReactiveVar 15
loadingNext = new ReactiveVar no

folders = [
	{
		name: 'inbox'
		friendlyName: 'Postvak in'
	}
	# {
	# 	name: 'drafts'
	# 	friendlyName: 'Concepten'
	# }
	{
		name: 'outbox'
		friendlyName: 'Verzonden'
	}
]

Template.messages.helpers
	composing: -> composing()
	isLoading: -> messages.get().length is 0 and isLoading.get()
	folder: -> _.find folders, name: currentFolder()
	hasMagister: -> hasMagister.get()
	currentMessage: -> currentMessage()

Template.messages.events
	'scroll': ->
		if loadingNext.get() or
		composing()
			return

		$page = document.getElementsByClassName('page')[0]
		atBottom = $page.scrollTop >= $page.scrollHeight - $page.clientHeight
		if atBottom
			loadingNext.set yes
			amount.set amount.get() + 10

Template.messages.onCreated ->
	tracker = new Tracker.Dependency()
	prev = _.now()
	@autorun ->
		minuteTracker.depend()
		now = _.now()
		if now - prev >= 180000 # 3 minutes
			tracker.changed()
			prev = now

	@autorun ->
		folder = currentFolder()
		if folder?
			messages.set []
			isLoading.set yes
		else
			isLoading.set no
	@autorun ->
		tracker.depend()

		folder = currentFolder()
		return unless folder?
		Meteor.call 'getMessages', folder, amount.get(), (e, r) ->
			loadingNext.set no
			isLoading.set no

			if e?.error is 'magister-only'
				hasMagister.set no
			else
				messages.set r

	@fillMessage = (message) ->
		Meteor.call 'fillMessage', message

	Meteor.defer ->
		if not currentFolder()? and Session.equals 'deviceType', 'desktop'
			FlowRouter.withReplaceState ->
				FlowRouter.setParams folder: folders[0].name

Template.messages.onRendered ->
	slide 'messages'
	setPageOptions
		title: 'Berichten'
		color: null

	@autorun ->
		$page = document.getElementsByClassName 'page'
		$page.scrollTop = 0

		if composing()
			setPageOptions title: 'Berichten | Nieuw bericht'
		else if currentMessage()?
			message = currentMessage()
			setPageOptions title: "Berichten | #{message.subject}"
		else if currentFolder()?
			folder = _.find folders, name: currentFolder()
			setPageOptions title: "Berichten | #{folder.friendlyName}"
		else
			setPageOptions title: 'Berichten'

Template['messages_sidebar'].helpers
	folders: -> folders

Template['messages_sidebar'].events
	'click #compose': ->
		FlowRouter.go 'composeMessage'

Template['messages_sidebar_folder'].helpers
	current: -> if currentFolder() is @name then 'current' else ''

Template['messages_messageList'].helpers
	messages: -> messages.get()
	loadingNext: -> loadingNext.get()

Template['messages_messageList'].events
	'click #closeButton': -> history.back()

Template['messages_message_row'].helpers
	__recipients: ->
		# TODO: make this based on length of the res string instead of amount of
		# items since they can vary in length.
		names = _.take @recipients, 2

		res = names.join ', '
		diff = @recipients.length - names.length
		if diff > 0
			res += " en #{diff} #{if diff is 1 then 'andere' else 'anderen'}."
		res

Template['messages_message_row'].events
	'click': -> setCurrentMessage @_id

Template['message_current_message'].helpers
	attachmentInfo: ->
		count = @attachmentCount
		"#{count} bijlage#{if count is 1 then '' else 'n'}"

Template['message_current_message'].events
	'click #closeButton': -> history.back()

Template['message_compose'].helpers
	recipients: -> _.unescape FlowRouter.getQueryParam 'recipients'

Template['message_compose'].events
	'click #send': ->
		subject = document.getElementById('subject').value
		recipients = document.getElementById('recipients').value
		body = document.getElementById('message').value

		Meteor.call(
			'composeMessage'
			subject
			body
			recipients.split(';').map((r) -> r.trim())
			(e, r) ->
				if e?
					notify 'Fout tijdens versturen van bericht', 'error'
					Kadira.trackError 'composeMessage-client', e.message, stacks: e.stack
				else
					notify 'Bericht verzonden', 'success'
					history.back()
		)
