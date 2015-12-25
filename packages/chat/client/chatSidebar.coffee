stayOpen = no
currentSearchTerm = new ReactiveVar ""

@chatRoomTransform = (room) ->
	switch room.type
		when 'private'
			user = ->
				Meteor.users.findOne
					_id:
						$in: room.users
						$ne: Meteor.userId()
		when 'project'
			project = -> Projects.findOne room.projectId

	_.extend room,
		user: user
		project: project

		status: ->
			u = user()
			if u?
				if u.status.idle then 'inactive'
				else if u.status.online then 'online'
				else 'offline'
		friendlyStatus: ->
			u = user()
			if u?
				if u.status.idle then 'inactief'
				else if u.status.online then 'online'
				else 'offline'

		sidebarIcon: ->
			switch room.type
				when 'private'
					picture user()
		friendlyName: ->
			switch room.type
				when 'project'
					project().name
				when 'private'
					u = user()
					if u? then "#{u.profile.firstName} #{u.profile.lastName}" else ''
				when 'group'
					room.subject ? ''

				else ''
		initial: -> Helpers.first(@friendlyName()).toUpperCase()

		unreadMessagesCount: ->
			Math.min 99, ChatMessages.find(
				creatorId: $ne: Meteor.userId()
				readBy: $ne: Meteor.userId()
				chatRoomId: room._id
			).count()

		markRead: -> Meteor.call 'markChatMessagesRead', room._id

###
# Static class for managing the currently open chat.
# @class ChatManager
###
class @ChatManager
	@MESSAGE_PER_PAGE: 40

	###*
	# Opens a chat window for the given user.
	# @method openUserChat
	# @param projectId {ObjectID|User} The user or an ID of an user to open a chat for.
	###
	@openUserChat: (userId) ->
		userId = userId._id if userId._id?
		@openChat ChatRooms.findOne(
			users: [ userId, Meteor.userId() ]
			projectId: $exists: no
		)?._id

	###*
	# Opens a chat window for the given project.
	# @method openProjectChat
	# @param projectId {ObjectID|Project} The project or an ID of a project to open a chat for.
	###
	@openProjectChat: (projectId) ->
		projectId = projectId._id if projectId._id?
		@openChat ChatRooms.findOne({ projectId })?._id

	###*
	# Opens a chat window for the given chatSidebar object.
	# @method openChat
	# @param object {Object} The chatSidebar context object to create a chatWindow for.
	###
	@openChat: (id) ->
		if Session.equals 'deviceType', 'phone'
			FlowRouter.go 'mobileChat', id: id
		else
			FlowRouter.setQueryParams openChatId: id

	###*
	# Closes the currently open chat.
	# @method closeChat
	###
	@closeChat: -> history.back()

###*
# Get the current chats, based on search term, if one.
#
# @method chats
# @param [searchTerm] {String}
# @return {Object[]} An array of ChatSidebar objects.
###
chats = (searchTerm = currentSearchTerm.get()) ->
	dam = DamerauLevenshtein insert: 0
	calcDistance = _.curry (s) -> dam searchTerm.trim().toLowerCase(), s.trim().toLowerCase()

	chatRooms = ChatRooms.find({}).fetch()

	_(chatRooms)
		.filter (chat) ->
			name = chat.friendlyName()
			searchTerm.trim() is '' or
			calcDistance(name) < 2 or
			Helpers.contains name, searchTerm, yes

		.sortBy (chat) -> chat.friendlyName()
		.sortBy (chat) ->
			name = chat.friendlyName()
			if searchTerm.trim() is ""
				-chat.lastMessageTime?.getTime()
			else
				distance = calcDistance name

				# If the name contains a word beginning with the query; lower distance a substensional amount.
				splitted = name.trim().toLowerCase().split ' '
				if _.any(splitted, (s) -> s.indexOf(searchTerm.trim().toLowerCase()) is 0)
					distance - 10
				else
					distance

		.value()

Template.chatSidebar.events
	'keyup div.searchBox': (event) ->
		if event.which is 27
			$('div.searchBox > input').blur()
		else if event.which is 13
			ChatManager.openChat chats()[0]._id
			currentSearchTerm.set event.target.value = ''
		else
			currentSearchTerm.set event.target.value

	'click #toggleChatNotify': ->
		# REVIEW: Should we sync this between clients?
		ReactiveLocalStorage 'chatNotify', not ReactiveLocalStorage 'chatNotify'

	'click .chatSidebarItem': ->
		ChatManager.openChat @_id

Template.chatSidebar.helpers
	chatNotifyEnabled: -> ReactiveLocalStorage 'chatNotify'
	chats: chats

Template.chatSidebar.onCreated ->
	@subscribe 'basicChatInfo', onReady: ->
		loadingObserve = yes

		lastNotifications = {}
		popoverTimeouts = {}
		audio = new Audio
		audio.src = "/audio/chatNotification.ogg"
		ChatMessages.find(
			creatorId: $ne: Meteor.userId()
			readBy: $ne: Meteor.userId()
		).observe
			added: (doc) ->
				return if loadingObserve or not ReactiveLocalStorage 'chatNotify'

				id = FlowRouter.getQueryParam 'openChatId'
				unless id? and
				document.hasFocus() and
				id is doc.chatRoomId
					audio.pause()
					audio.play()

					sender = Meteor.users.findOne doc.creatorId
					chatId = doc.chatRoomId

					if document.hasFocus()
						Meteor.clearTimeout popoverTimeouts[chatId]

						$sidebarItem = $("##{chatId}")
							.popover 'destroy'
							.popover
								title: "Bericht van #{sender.profile.firstName}"
								content: doc.content
								html: yes
								placement: 'left'
								animation: yes
								trigger: 'manual'
								container: '.chatSidebar'
							.popover 'show'

						popoverTimeouts[chatId] = Meteor.setTimeout (->
							$sidebarItem.popover 'destroy'
						), 2500

					else if Session.get 'allowNotifications'
						chatRoom = ChatRooms.findOne chatId

						title = (
							if chatRoom.type is 'private'
								chatRoom.friendlyName()
							else
								"#{sender.profile.firstName} in #{chatRoom.friendlyName()}"
						)
						body = "#{title}\n#{doc._originalContent ? doc.content}"
						window.stuff = { doc, chatRoom, sender, body }

						lastNotifications[chatId]?.hide()
						lastNotifications[chatId] = NotificationsManager.notify
							body: body
							image: picture sender, 500
							onClick: -> ChatManager.openChat chatId

		loadingObserve = no

Template.chatSidebar.onRendered ->
	# some of that caching, yo.
	$body = $ "body"
	$chats = @$ ".chats"
	$input = @$ "input"

	ReactiveLocalStorage 'chatNotify', yes

	if Session.equals 'deviceType', 'desktop'
		# Attach classes to body on chatSidebar hover / blur
		$(".chatSidebar").hover (->
			$body.addClass "chatSidebarOpen"
		), ->
			return if stayOpen
			$body.removeClass "chatSidebarOpen"
			$chats.animate scrollTop: 0

			currentSearchTerm.set ""
			$input.val ""

		$input.on "focus", ->
			stayOpen = yes
			$body.addClass "chatSidebarOpen"

		$input.on "blur", ->
			stayOpen = no
			$body.removeClass "chatSidebarOpen"
			$chats.animate scrollTop: 0

			currentSearchTerm.set ""
			$input.val ""
