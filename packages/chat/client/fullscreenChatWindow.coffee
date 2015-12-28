editMessageId = new ReactiveVar

send = (content, updateId) ->
	content = content.trim()
	return if content.length is 0

	if updateId?
		Meteor.call 'updateChatMessage', content, updateId
	else
		Meteor.call 'addChatMessage', content, @_id

	document.getElementById('messageInput').value = ''

Template.fullscreenChatWindow.helpers
	__editing: -> if editMessageId.get()? then 'editing' else ''

Template.fullscreenChatWindow.events
	"click #header": (e) ->
		FlowRouter.withReplaceState =>
			switch @type
				when 'private'
					FlowRouter.go 'personView', id: @user()._id
				when 'project'
					FlowRouter.go 'projectView', id: @project()._id.toHexString()

	"click .closeChat": -> ChatManager.closeChat()

	'click .sendButton': (event) ->
		$input = document.getElementById 'messageInput'
		send.call this, $input.value
		window.sendToBottom()
		$input.focus()

	"keyup input#messageInput": (event) ->
		content = event.target.value

		previousMessage = =>
			ChatMessages.findOne {
				creatorId: Meteor.userId()
				chatRoomId: @_id
			}, {
				sort: 'time': -1
			}

		if event.which is 38
			# edit the previous message.
			message = previousMessage()
			event.target.value = message._originalContent
			editMessageId.set message._id
		else if event.which is 40 and editMessageId.get()?
			# stop editing the previous mesasge.
			event.target.value = ''
			editMessageId.set undefined

		else if event.which is 27
			ChatManager.closeChat()

		else if event.which is 13
			if Helpers.sed(content)
				message = previousMessage()
				if message?
					changed = Helpers.sed content, message._originalContent
					send.call this, changed, message._id
				else
					event.target.value = ''
			else
				send.call this, content, editMessageId.get()
				editMessageId.set undefined

			window.sendToBottom()

	'blur input#messageInput': (event) ->
		event.target.focus()

Template.fullscreenChatWindow.onCreated ->
	@subscribe 'status', @data.users

Template.fullscreenChatWindow.onRendered ->
	document.getElementById('messageInput').focus()
