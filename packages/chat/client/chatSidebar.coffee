NOTIFICATION_SOUND_SRC = 'https://www.simplyhomework.nl/static/audio/chatNotification.ogg'

currentSearchTerm = new ReactiveVar ''

###*
# @method chatRoomTransform
# @param {ChatRoom} room
# @return {ChatRoom}
###
@chatRoomTransform = (room) ->
	user = ->
		if room.type is 'private'
			Meteor.users.findOne
				_id:
					$in: room.users
					$ne: Meteor.userId()
	project = ->
		if room.type is 'project'
			Projects.findOne room.projectId
	_class = ->
		if room.type is 'class' and room.classInfo.ids.length is 1
			Classes.findOne _id: $in: room.classInfo.ids

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
				when 'group', 'class'
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
# @static
###
class @ChatManager
	@MESSAGES_PER_PAGE: 30

	###*
	# Opens the chat for with given user.
	# @method openPrivateChat
	# @param userId {User} The user to open the chat of.
	###
	@openPrivateChat: (userId) ->
		room = ChatRooms.findOne
			type: 'private'
			users: [ userId, Meteor.userId() ]

		if room?
			@openChat room._id
		else
			Meteor.call 'createPrivateChatRoom', userId, (e, r) ->
				ChatManager.openChat r

	###*
	# Opens the chat for with given project.
	# @method openProjectChat
	# @param projectId {Project} The project to open the chat of.
	###
	@openProjectChat: (projectId) ->
		@openChat ChatRooms.findOne({ projectId })?._id

	@openClassChat: (classId) ->
		@openChat ChatRooms.findOne({ 'classInfo.ids': classId })?._id

	###*
	# Opens the chat for the given ChatRoom id
	# @method openChat
	# @param id {String} ID of a ChatRoom.
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
# @param {String} [searchTerm]
# @param {Boolean} [onlyFirst=false]
# @return {Object[]} An array of ChatSidebar objects.
###
chats = (searchTerm = currentSearchTerm.get(), onlyFirst = no) ->
	dam = DamerauLevenshtein insert: 0
	calcDistance = _.curry (s) -> dam searchTerm.trim().toLowerCase(), s.trim().toLowerCase()

	chatRooms = ChatRooms.find({
		lastMessageTime: $exists: yes
	}).fetch()

	chain = _(chatRooms)
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

	if onlyFirst then chain.first()
	else chain.value()

Template.chatSidebar.events
	'keyup div.searchBox': (event) ->
		if event.which is 27
			$('div.searchBox > input').blur()
		else if event.which is 13
			ChatManager.openChat chats(undefined, no)[0]._id
			$('div.searchBox > input').blur()
		else
			currentSearchTerm.set event.target.value

	'click #toggleChatNotify': ->
		# REVIEW: Should we sync this between clients?
		ReactiveLocalStorage 'chatNotify', not ReactiveLocalStorage 'chatNotify'

	'click .chatSidebarItem': ->
		closeSidebar?()
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
		audio.src = NOTIFICATION_SOUND_SRC
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
	$body = $ 'body'
	$chats = @$ '.chats'
	$input = @$ 'input'

	unless ReactiveLocalStorage('chatNotify')?
		ReactiveLocalStorage 'chatNotify', yes

	$input.on 'blur', (event) ->
		currentSearchTerm.set ''
		event.target.value = ''

	if Session.equals 'deviceType', 'desktop'
		stayOpen = no

		$('.chatSidebar').hover (->
			$body.addClass 'chatSidebarOpen'
		), ->
			return if stayOpen
			$body.removeClass 'chatSidebarOpen'
			$chats.animate scrollTop: 0

			currentSearchTerm.set ''
			$input.val ''

		$input.on 'focus', ->
			stayOpen = yes
			$body.addClass 'chatSidebarOpen'

		$input.on 'blur', ->
			stayOpen = no
			$body.removeClass 'chatSidebarOpen'
			$chats.animate scrollTop: 0
