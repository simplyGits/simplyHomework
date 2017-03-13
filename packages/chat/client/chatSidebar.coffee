{ isDesktop } = require 'meteor/device-type'

DamerauLevenshtein = require 'damerau-levenshtein'

NOTIFICATION_SOUND_SOURCES = [
	[ 'audio/ogg', '/packages/chat/audio/chatNotification.ogg' ]
	[ 'audio/mpeg', '/packages/chat/audio/chatNotification.mp3' ]
]

currentSearchTerm = new ReactiveVar ''

###*
# @method chatRoomTransform
# @param {ChatRoom} room
# @return {ChatRoom}
###
@chatRoomTransform = (room) ->
	userId = (
		if room.type is 'private'
			_.find room.users, (u) -> u isnt Meteor.userId()
	)
	user = ->
		if room.type is 'private'
			Meteor.users.findOne _id: userId

	project = ->
		if room.type is 'project'
			Projects.findOne room.projectId

	_class = ->
		if room.type is 'class' and room.classInfo.ids.length is 1
			Classes.findOne _id: $in: room.classInfo.ids

	_.extend room,
		user: user
		project: project
		class: _class

		status: -> getUserStatus userId
		friendlyStatus: ->
			switch getUserStatus userId
				when 'online' then 'online'
				when 'inactive' then 'inactief'
				when 'offline' then 'offline'

		sidebarIcon: -> room.getPicture Meteor.userId(), 100
		friendlyName: -> room.getSubject Meteor.userId()
		initial: -> Helpers.first(@friendlyName()).toUpperCase()

		items: ->
			chatMessages = ChatMessages.find({ chatRoomId: room._id }).fetch()
			_(room.events)
				.filter (event) ->
					allLoaded = chatMessages.length >= Counts.get 'chatMessageCount'
					inTime = _.any chatMessages, (i) ->
						i.time.getTime() < event.time.getTime()

					allLoaded or inTime
				.map (event) ->
					event: yes
					content: (
						time = Helpers.formatDate event.time, yes
						userUrl = ''

						u = Meteor.users.findOne event.userId
						if u?
							{ firstName, lastName } = u.profile
							name = "#{_.escape firstName} #{_.escape lastName}"
							path = FlowRouter.path 'personView', id: u._id
							userUrl = "<a href='#{path}'>#{name}</a>"

							switch event.type
								when 'created'
									if room.type is 'class' then "Chat aangemaakt #{time}"
									else "Chat aangemaakt door #{userUrl} #{time}"
								when 'joined' then "#{userUrl} is de chat binnengekomen #{time}"
								when 'left' then "#{userUrl} heeft de chat verlaten #{time}"
						else
							switch event.type
								when 'created' then "Chat aangemaakt #{time}"
								when 'joined' then "Iemand is de chat binnengekomen #{time}"
								when 'left' then "Iemand heeft de chat verlaten #{time}"
					)
					time: event.time
					type: event.type
				.concat chatMessages
				.sortBy 'time'
				.value()

		unreadMessagesCount: ->
			count = ChatMessages.find(
				creatorId: $ne: Meteor.userId()
				readBy: $ne: Meteor.userId()
				chatRoomId: room._id
			).count()

			if count > 99 then ':D'
			else count

		markRead: -> Meteor.call 'markChatMessagesRead', room._id

###
# Static class for managing the currently open chat.
# @class ChatManager
# @static
###
class @ChatManager
	@MESSAGES_PER_PAGE: 50

	###*
	# Opens the chat with given user.
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
				if e?
					notify (
						switch e.error
							when 'same-person' then 'Je kan niet een chat met jezelf maken'
							else 'Onbekende fout'
					), 'error'
				else
					ChatManager.openChat r

	###*
	# Opens the chat for with given project.
	# @method openProjectChat
	# @param projectId {Project} The project to open the chat of.
	###
	@openProjectChat: (projectId) ->
		@openChat ChatRooms.findOne({ projectId })?._id

	###*
	# Opens the classgroup chat for group of the user for the given class ID.
	# @method openClassChat
	# @param {String} classId
	###
	@openClassChat: (classId) ->
		@openChat ChatRooms.findOne(
			type: 'class'
			'classInfo.ids': classId
		)?._id

	###*
	# Opens the chat for the given ChatRoom id
	# @method openChat
	# @param id {String} ID of a ChatRoom.
	###
	@openChat: (id) ->
		FlowRouter.go 'chat', { id }

	###*
	# Closes the currently open chat.
	# @method closeChat
	###
	@closeChat: ->
		history.back()

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

				# If the name contains a word beginning with the query; lower distance a substantial amount.
				splitted = name.trim().toLowerCase().split ' '
				if _.any(splitted, (s) -> s.indexOf(searchTerm.trim().toLowerCase()) is 0)
					distance - 10
				else
					distance

	if onlyFirst then chain.first()
	else chain.value()

getChatNotify = ->
	getUserField Meteor.userId(), 'settings.notifications.notif.chat', yes
setChatNotify = (val) ->
	check val, Boolean
	Meteor.users.update Meteor.userId(), $set: 'settings.notifications.notif.chat': val

Template.chatSidebar.events
	'keyup div.searchBox': (event) ->
		if event.which is 27
			$('div.searchBox > input').blur()
		else if event.which is 13
			ChatManager.openChat chats(undefined, no)[0]._id
			$('div.searchBox > input').blur()
		else
			currentSearchTerm.set event.target.value

	'click #toggleChatNotify': -> setChatNotify not getChatNotify()

	'click .chatSidebarItem': ->
		closeSidebar?()
		ChatManager.openChat @_id

Template.chatSidebar.helpers
	chatNotifyEnabled: -> getChatNotify()
	chats: chats

Template.chatSidebar.onCreated ->
	@subscribe 'basicChatInfo', onReady: ->
		loadingObserve = yes

		lastNotifications = {}
		popoverTimeouts = {}

		audio = new Audio
		for [ type, src ] in NOTIFICATION_SOUND_SOURCES
			source = document.createElement 'source'
			source.type = type
			source.src = src
			audio.appendChild source

		ChatMessages.find(
			creatorId: $ne: Meteor.userId()
			readBy: $ne: Meteor.userId()
		).observe
			added: (doc) ->
				return if loadingObserve or not getChatNotify()

				id = (
					if FlowRouter.getRouteName() is 'chat'
						FlowRouter.getParam 'id'
				)
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

	$input.on 'blur', (event) ->
		currentSearchTerm.set ''
		event.target.value = ''

	if isDesktop()
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

	else
		Meteor.defer ->
			prev = undefined
			snapper.on 'animated', ->
				state = snapper.state()

				if prev?.state is 'right' and
				state.state is 'closed'
					$chats.animate scrollTop: 0

				prev = state
