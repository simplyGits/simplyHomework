send = (content, updateId) ->
	content = content.trim()
	return if content.length is 0

	if updateId?
		Meteor.call 'updateChatMessage', content, updateId
	else
		Meteor.call 'addChatMessage', content, @_id

	document.getElementById('messageInput').value = ''

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
			_.findLast @messages().fetch(), (cm) ->
				cm.creatorId is Meteor.userId()

		if event.which is 38
			# edit the previous message.
			message = previousMessage()

			event.target.value = message._originalContent
			@editMessageId = message._id

		else if event.which is 27
			ChatManager.closeChat()

		else if event.which is 13
			if Helpers.sed content
				message = previousMessage()
				if message?
					changed = Helpers.sed content, message._originalContent, undefined
					send.call this, changed, message._id
				else
					event.target.value = ''
			else
				send.call this, content, @editMessageId
				@editMessageId = undefined

			window.sendToBottom()

Template.fullscreenChatWindow.onCreated ->
	@subscribe 'status', @data.users

Template.fullscreenChatWindow.onRendered ->
	document.getElementById('messageInput').focus()
