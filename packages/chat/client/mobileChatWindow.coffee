chatRoom = ->
	ChatRooms.findOne {
		_id: FlowRouter.getParam('id')
	}, {
		fields:
			lastMessageTime: 0
	}

handleMessageInput = (input) ->
	content = input.value.trim()
	return if content.length is 0

	id = FlowRouter.getParam 'id'

	if Helpers.sed content
		message = ChatMessages.findOne {
			creatorId: Meteor.userId()
			chatRoomId: id
		}, sort: time: -1
		changed = Helpers.sed content, message._originalContent
		Meteor.call 'updateChatMessage', changed, message._id
	else
		Meteor.call 'addChatMessage', content, id

	input.value = ''
	input.focus()
	window.sendToBottom()

Template.mobileChatWindow.helpers
	chat: -> chatRoom()
	__noHeader: -> if not @sidebarIcon()? then 'noHeader' else ''

Template.mobileChatWindow.events
	"click div.header": ->
		if @type is 'private'
			FlowRouter.go 'personView', id: @user()._id
		else if @type is 'private'
			FlowRouter.go 'projectView', id: @project()._id
		else if @type is 'class' and @class()?
			FlowRouter.go 'classView', id: @class()._id

	'keyup input#messageInput': (event) ->
		handleMessageInput event.target if event.which is 13

	'click #sendButton': ->
		handleMessageInput document.getElementById 'messageInput'

Template.mobileChatWindow.onCreated ->
	@sticky = yes
	@subscribe 'basicChatInfo'

	@autorun =>
		room = chatRoom()
		if room?
			@subscribe 'status', room.users
			setPageOptions
				title: "Chat: #{room.friendlyName()}"
				color: null

Template.mobileChatWindow.onRendered ->
	slide()
