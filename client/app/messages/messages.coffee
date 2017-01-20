Meteor.startup ->
	Tracker.autorun ->
		return unless Meteor.userId()?

		raw = localStorage.getItem('pending_drafts') ? '[]'
		drafts = EJSON.parse raw

		for draft in drafts
			Meteor.call 'saveMessageDraft', draft

		localStorage.removeItem 'pending_drafts'

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

hasMore = -> offset.get() + 20 < Counts.get 'messageCount'

folders = [{
	name: 'inbox'
	friendlyName: 'Postvak in'
}, {
	name: 'drafts'
	friendlyName: 'Concepten'
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
			Meteor.subscribe 'messageCount', folder
			Meteor.subscribe 'messages', offset.get(), [ folder ], onStop: (e) ->
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
		ga 'send', 'event', 'messages', 'compose', 'new'
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
	'click [data-action="reply"]': ->
		ga 'send', 'event', 'messages', 'compose', 'reply'
		FlowRouter.go 'composeMessage', undefined,
			replyId: @_id
			recipients: @sender.fullName
			subject: "RE: #{@subject}"
			body: """
			\n
			---

			Oorspronkelijk bericht:
			Van: #{@sender.fullName}
			Verzonden: #{moment(@sendDate).format 'dddd D MMMM YYYY HH:mm'}
			Aan: #{@recipientsString Infinity, no}
			Onderwerp: #{@subject}

			#{@body}
			"""

Template['message_current_message'].onCreated ->
	@autorun =>
		id = getCurrentMessageId()
		@subscribe 'message', id

		message = Messages.findOne id
		if message?
			@subscribe 'files', message.attachmentIds

			unless message.isRead
				Meteor.call 'markMessageRead', id

savingDraft = new ReactiveVar no
setSavingStatus = _.debounce ((state) ->
	savingDraft.set state
), 350

saveDraft = _.debounce ((draft) ->
	setSavingStatus yes

	localStorage.setItem 'pending_drafts',
		EJSON.stringify (
			raw = localStorage.getItem('pending_drafts') ? '[]'
			x = _.reject EJSON.parse(raw), _id: draft._id
			x.push draft
			x
		)

	Meteor.call 'saveMessageDraft', draft, (e, r) ->
		setSavingStatus no unless e?
), 500

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

	draftSaveStatus: ->
		if savingDraft.get()
			'Concept aan het opslaan...'
		else
			'Concept opgeslagen.'

sending = no
Template['message_compose'].events
	'keyup': ->
		subject = document.getElementById('subject').value
		recipients = document.getElementById('recipients').value
		body = document.getElementById('message').value

		draft = new Draft(
			subject
			body
			Meteor.userId()
		)
		draft.recipients = _(recipients)
			.split ';'
			.map (r) -> r.trim()
			.reject (r) -> r.length is 0
			.value()
		draft.senderService = 'magister'

		draftId = FlowRouter.getQueryParam 'draftId'
		if draftId?
			draft._id = draftId
		else
			FlowRouter.withReplaceState ->
				FlowRouter.setQueryParams draftId: draft._id

		saveDraft draft

	'click #send': ->
		return if sending
		sending = yes

		subject = document.getElementById('subject').value
		recipients = document.getElementById('recipients').value
		body = document.getElementById('message').value.trim()

		if body.length is 0
			notify 'Inhoud kan niet leeg zijn', 'error'
			return undefined

		replyId = FlowRouter.getQueryParam 'replyId'

		cb = (e, r) ->
			sending = no

			if e?
				notify 'Fout tijdens versturen van bericht', 'error'
				Kadira.trackError 'composeMessage-client', e.message, stacks: e.stack
			else
				notify 'Bericht verzonden', 'success'
				history.back()

		if replyId?
			ga 'send', 'event', 'messages', 'send', 'reply'
			Meteor.call(
				'replyMessage'
				replyId
				no
				body
				FlowRouter.getQueryParam 'draftId'
				cb
			)
		else
			ga 'send', 'event', 'messages', 'send', 'new'
			Meteor.call(
				'sendMessage'
				subject
				body
				recipients.split(';').map (r) -> r.trim()
				'magister'
				FlowRouter.getQueryParam 'draftId'
				cb
			)
