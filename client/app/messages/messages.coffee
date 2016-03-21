getCurrentFolder = -> FlowRouter.getParam 'folder'
getMessages = ->
	folder = getCurrentFolder()
	sort = sendDate: -1

	if folder is 'drafts'
		Drafts.find {}, { sort }
	else
		Messages.find { folder }, { sort }

getCurrentMessageId = -> FlowRouter.getParam 'message'
setCurrentMessage = (id) -> FlowRouter.setParams message: id

getCurrentDraft = -> Drafts.findOne FlowRouter.getQueryParam 'draftId'

isComposing = -> FlowRouter.getRouteName() is 'composeMessage'

hasService = new ReactiveVar yes
offset = new ReactiveVar 0
isLoadingNext = new ReactiveVar no

hasMore = -> offset.get() + 20 < Counts.get 'messagesCount'

folders = [{
	name: 'inbox'
	friendlyName: 'Postvak in'
}, {
	name: 'drafts'
	friendlyName: 'Concepten'
}, {
	name: 'alerts'
	friendlyName: 'Meldingen'
}, {
	name: 'outbox'
	friendlyName: 'Verzonden'
}]

Template.messages.helpers
	isComposing: -> isComposing()
	folder: -> _.find folders, name: getCurrentFolder()
	hasService: -> hasService.get()
	hasCurrentMessage: -> getCurrentMessageId()?

Template.messages.onCreated ->
	@autorun -> # reset stuff
		folder = getCurrentFolder()
		offset.set 0

	@autorun -> # subscribe to messages
		folder = getCurrentFolder()

		if folder is 'drafts' or FlowRouter.getQueryParam('draftId')?
			Meteor.subscribe 'draftsCount'
			Meteor.subscribe 'drafts', offset.get(), ->
				isLoadingNext.set no

		else if folder?
			Meteor.subscribe 'messagesCount', folder
			Meteor.subscribe 'messages', offset.get(), [ folder ], (e) ->
				isLoadingNext.set no
				if e?.error is 'not-supported'
					hasService.set no

	Meteor.defer -> # autoselect first folder on desktop
		if not getCurrentFolder()? and Session.equals 'deviceType', 'desktop'
			FlowRouter.withReplaceState ->
				FlowRouter.setParams folder: folders[0].name

Template.messages.onRendered ->
	@autorun ->
		$page = document.getElementsByClassName 'page'
		$page.scrollTop = 0

		slide 'messages'
		setPageOptions
			color: null
			title: (
				suffix = (
					if isComposing()
						'Nieuw bericht'
					else if getCurrentMessageId()?
						Messages.findOne(getCurrentMessageId())?.subject
					else if getCurrentFolder()?
						folder = _.find(folders, name: getCurrentFolder())?.friendlyName
				)

				if suffix?
					"Berichten | #{suffix}"
				else
					'Berichten'
			)

Template['messages_sidebar'].helpers
	folders: -> folders
	hasService: -> hasService.get()

Template['messages_sidebar'].events
	'click #compose': ->
		FlowRouter.go 'composeMessage'

Template['messages_sidebar_folder'].helpers
	current: -> if getCurrentFolder() is @name then 'current' else ''

Template['messages_messageList'].helpers
	messages: -> getMessages()
	isLoadingNext: -> isLoadingNext.get()
	hasMore: -> hasMore()

Template['messages_messageList'].events
	'click .loadMore': ->
		unless isLoadingNext.get()
			isLoadingNext.set yes
			offset.set offset.get() + 15
	'scroll': ->
		unless isLoadingNext.get()
			$list = document.getElementById 'messageList'
			atBottom = $list.scrollTop >= $list.scrollHeight - $list.clientHeight
			if atBottom
				isLoadingNext.set yes
				offset.set offset.get() + 15
	'click #closeButton': -> history.back()

Template['messages_message_row'].helpers
	__recipients: -> @recipientsString 2, no
	recipientCount: -> @recipients.length
	isDraft: -> this instanceof Draft

Template['messages_message_row'].events
	'click': ->
		if this instanceof Draft
			FlowRouter.go 'composeMessage', undefined, draftId: @_id
		else
			setCurrentMessage @_id

Template['message_current_message'].helpers
	message: -> Messages.findOne getCurrentMessageId()

	senderString: ->
		user = Meteor.users.findOne @sender.userId
		if user?
			fullName = "#{user.profile.firstName} #{user.profile.lastName}"
			path = FlowRouter.path 'personView', id: user._id
			"<a href='#{path}'>#{fullName}</a>"
		else
			@sender.fullName

	recipientCount: -> @recipients.length

	attachmentCount: -> @attachmentIds.length
	attachments: ->
		@attachments()
			.map (file) -> file.buildAnchorTag().outerHTML
			.join ', '

Template['message_current_message'].events
	'click #closeButton': -> history.back()

Template['message_current_message'].onCreated ->
	@autorun =>
		id = getCurrentMessageId()
		@subscribe 'message', id

		message = Messages.findOne id
		if message?
			@subscribe 'files', message.attachmentIds

			if Meteor.userId() not in message.readBy
				Meteor.call 'markMessageRead', id

saveDraft = _.throttle ((args...) ->
	Meteor.call 'saveMessageDraft', args...
), 850,
	leading: yes
	trailing: no

Template['message_compose'].helpers
	subject: ->
		getCurrentDraft()?.subject ?
		_.unescape FlowRouter.getQueryParam 'subject'

	recipients: ->
		getCurrentDraft()?.recipients.join('; ') ?
		_.unescape FlowRouter.getQueryParam 'recipients'

	body: ->
		getCurrentDraft()?.body ?
		_.unescape FlowRouter.getQueryParam 'body'

Template['message_compose'].events
	'keyup': ->
		subject = document.getElementById('subject').value
		recipients = document.getElementById('recipients').value
		body = document.getElementById('message').value.trim()

		saveDraft(
			subject
			body
			recipients.split(';').map (r) -> r.trim()
			'magister'
			FlowRouter.getQueryParam 'draftId'
		)

	'click #send': ->
		subject = document.getElementById('subject').value
		recipients = document.getElementById('recipients').value
		body = document.getElementById('message').value.trim()

		if body.length is 0
			notify 'Inhoud kan niet leeg zijn', 'error'
			return undefined

		Meteor.call(
			'sendMessage'
			subject
			body
			recipients.split(';').map (r) -> r.trim()
			'magister'
			FlowRouter.getQueryParam 'draftId'
			(e, r) ->
				if e?
					notify 'Fout tijdens versturen van bericht', 'error'
					Kadira.trackError 'composeMessage-client', e.message, stacks: e.stack
				else
					notify 'Bericht verzonden', 'success'
					history.back()
		)
