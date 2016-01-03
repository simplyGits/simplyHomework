chatRoom = ->
	ChatRooms.findOne {
		_id: FlowRouter.getParam('id')
	}, {
		fields:
			lastMessageTime: 0
	}

Template.mobileChatWindow.helpers
	chat: -> chatRoom()
	__noHeader: -> if not @sidebarIcon()? then 'noHeader' else ''

Template.mobileChatWindow.events
	"click div.header": ->
		switch @type
			when 'private'
				FlowRouter.go 'personView', id: @user()._id
			when 'project'
				FlowRouter.go 'projectView', id: @project()._id.toHexString()

	'keyup input#messageInput': (event) ->
		content = event.target.value.trim()

		if event.which is 13 and content.length > 0
			Meteor.call 'addChatMessage', content, FlowRouter.getParam('id')

			event.target.value = ''
			window.sendToBottom()

	'click #sendButton': ->
		$input = document.getElementById 'messageInput'

		content = $input.value.trim()
		Meteor.call 'addChatMessage', content, FlowRouter.getParam('id')

		$input.value = ''
		window.sendToBottom()

Template.mobileChatWindow.onCreated ->
	@sticky = yes
	@subscribe 'basicChatInfo', onReady: =>
		room = chatRoom()
		if room?
			@subscribe 'status', room.users
			setPageOptions
				title: "#{room.friendlyName()} chat"
				color: null
		else
			notFound()

Template.mobileChatWindow.onRendered ->
	slide()
