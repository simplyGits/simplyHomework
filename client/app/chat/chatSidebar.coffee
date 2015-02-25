stayOpen = no
searchTerm = new ReactiveVar ""

@userChatTransform = (u) ->
	subs.subscribe "chatMessages", { userId: u._id }, 10

	return _.extend u,
		__initial: null
		__sidebarIcon: gravatar u
		__type: "private"

		__lastInteraction: -> ChatMessages.findOne({ $or: [ { to: u._id }, { creatorId: u._id } ] }, sort: "time": -1)?.time
		__status: (
			if u.status.idle then "inactive"
			else if u.status.online then "online"
			else "offline"
		)
		__friendlyName: "#{u.profile.firstName} #{u.profile.lastName}"

		__markRead: -> Meteor.call "markChatMessagesRead", "direct", u._id
		__unreadMessagesCount: -> ChatMessages.find({ creatorId: u._id, to: Meteor.userId(), readBy: $ne: Meteor.userId() }).count()
		__close: -> ChatManager.closeChat u

		_fetching: no
		__topMessages: 10
		__fetchNextPage: ->
			return if @_fetching
			@_fetching = yes
			subs.subscribe "chatMessages", { userId: u._id }, @__topMessages += 10, => @_fetching = no
		__messages: -> ChatMessages.find({
			$or: [
				{ creatorId: Meteor.userId(), to: u._id }
				{ creatorId: u._id, to: Meteor.userId() }
			]
		}, transform: chatMessageTransform, sort: "time": 1).fetch()

@projectChatTransform = (p) ->
	subs.subscribe "chatMessages", { projectId: p._id }, 10

	return _.extend p,
		__initial: p.name[0].toUpperCase()
		__sidebarIcon: null
		__type: "project"

		__lastInteraction: -> ChatMessages.findOne({ projectId: p._id }, sort: "time": -1)?.time
		__status: ""
		__friendlyName: p.name

		__markRead: -> Meteor.call "markChatMessagesRead", "project", p._id
		__unreadMessagesCount: -> ChatMessages.find({ creatorId: { $ne: Meteor.userId() }, projectId: p._id, readBy: $ne: Meteor.userId() }).count()
		__close: -> ChatManager.closeChat p

		_fetching: no
		__topMessages: 10
		__fetchNextPage: ->
			return if @_fetching
			@_fetching = yes
			subs.subscribe "chatMessages", { projectId: p._id }, @__topMessages += 10, => @_fetching = no
		__messages: -> ChatMessages.find({
			projectId: p._id
		}, transform: chatMessageTransform, sort: "time": 1).fetch()

###
# Static class for managing currently open chats.
# @class ChatManager
###
class @ChatManager
	@openChats: new ReactiveVar []

	###*
	# Opens a chat window for the given user.
	# @method openUserChat
	# @param projectId {ObjectID|User} The user or an ID of an user to open a chat for.
	###
	@openUserChat: (userId) ->
		userId = userId._id if userId._id?
		chat = Meteor.users.findOne userId, transform: userChatTransform

		@openChat chat

	###*
	# Opens a chat window for the given project.
	# @method openProjectChat
	# @param projectId {ObjectID|Project} The project or an ID of a project to open a chat for.
	###
	@openProjectChat: (projectId) ->
		projectId = projectId._id if projectId._id?
		chat = Projects.findOne projectId, transform: projectChatTransform

		@openChat chat

	###*
	# Opens a chat window for the given chatSidebar object.
	# @method openChat
	# @param object {Object} The chatSidebar context object to create a chatWindow for.
	###
	@openChat: (object) ->
		if Session.get "isPhone"
			if object.__type is "private"
				Router.go "mobileChatWindow", object

			else if object.__type is "project"
				Router.go "mobileChatWindow", _id: object._id.toHexString()

		else
			stayOpen = yes
			$("body").addClass "chatSidebarOpen"

		object.__markRead()
		unless _.any(@openChats.get(), (c) -> EJSON.equals c._id, object._id)
			@openChats.set @openChats.get().concat [object]

	###*
	# Closes the open chat window for the given object.
	# Does nothing if there isn't a chatWindow open for the given `object`.
	#
	# @method closeChat
	# @param object {Object} The chatSidebar context object to close the open chatWindow for.
	###
	@closeChat: (object) ->
		@openChats.set _.without @openChats.get(), object

###*
# Get the current chats, based on search term, if one.
#
# @method chats
# @return {Object[]} An array of ChatSidebar objects.
###
chats = ->
	comp = Tracker.currentComputation

	dam = DamerauLevenshtein insert: 0
	caseInsensitive = searchTerm.get() is searchTerm.get().toLowerCase()

	calcDistance = null
	if caseInsensitive
		calcDistance = _.curry (s) -> dam searchTerm.get().trim().toLowerCase(), s.trim().toLowerCase()
	else
		calcDistance = _.curry (s) -> dam searchTerm.get().trim(), s.trim()

	users = Meteor.users.find({ _id: $ne: Meteor.userId() }, transform: userChatTransform).fetch()
	projects = Projects.find({}, sort: { "deadline": 1, "name": 1 }, transform: projectChatTransform).fetch()

	groups = [] # Later when we implement groups.

	return _(users.concat(projects).concat(groups))
		.filter (chat) -> searchTerm.get().trim() is "" or calcDistance(chat.__friendlyName) < 2 or Helpers.contains chat.__friendlyName, searchTerm.get(), caseInsensitive
		.sortBy (chat) ->
			if searchTerm.get().trim() is ""
				# Make search reactive
				t = Tracker.autorun ->
					chat.__lastInteraction()
					comp.invalidate()
				comp.onInvalidate -> t.stop()

				return chat.__lastInteraction()
			else
				distance = DamerauLevenshtein()(searchTerm.get().trim().toLowerCase(), chat.__friendlyName.trim().toLowerCase())

				trimmed = chat.__friendlyName.trim().toLowerCase()
				# If the name contains a word beginning with the query; lower distance a substensional amount.
				if (index = trimmed.indexOf searchTerm.get().trim().toLowerCase()) is 0 or trimmed[index - 1] is " " then distance -= 10

				return distance
		.value()

Template.chatSidebar.events
	"keyup div.searchBox": (event) ->
		if event.which is 27
			$("div.searchBox > input").blur()
			return
		else if event.which is 13
			ChatManager.openChat chats()[0], $(".chatSidebarItem:first-child").get()[0]
			searchTerm.set event.target.value = ""
			return

		searchTerm.set event.target.value

	"click .chatSidebarItem": (event) -> ChatManager.openChat @, event.currentTarget

Template.chatSidebar.helpers
	openChats: -> ChatManager.openChats.get()
	chats: chats

Template.chatSidebar.rendered = ->
	unless Session.get "isPhone"
		# Attach classes to body on chatSidebar hover / blur
		$("div.chatSidebar").hover (->
			if ChatManager.openChats.get().length > 0
				stayOpen = yes

			$("body").addClass "chatSidebarOpen"
		), (->
			return if stayOpen
			$("body").removeClass "chatSidebarOpen"
			$("div.chatSidebar > div.chats").animate scrollTop: 0

			searchTerm.set ""
			$("div.searchBox > input").val ""
		)

		$("body").on "focus", "div.searchBox > input, .messageInput", ->
			stayOpen = yes
			$("body").addClass "chatSidebarOpen"

		$("body").on "blur", "div.searchBox > input, .messageInput", ->
			stayOpen = no
			$("body").removeClass "chatSidebarOpen"
			$("div.chatSidebar > div.chats").animate scrollTop: 0

			searchTerm.set ""
			$("div.searchBox > input").val ""

	loadingObserve = yes

	audio = new Audio; audio.src = "/audio/chatNotification.ogg"
	ChatMessages.find(
		creatorId: $ne: Meteor.userId()
		readBy: $ne: Meteor.userId()
	).observe
		added: (doc) ->
			return if loadingObserve

			audio.pause()
			audio.play()

			unless document.hasFocus() or not Session.get "allowNotifications"
				sender = Meteor.users.findOne doc.creatorId
				project = Projects.findOne doc.projectId

				body = "#{_.escape sender.profile.firstName}"
				body += " in #{project.name}" if project?
				body += ": #{_.escape doc.content}"

				NotificationsManager.notify
					body: body
					image: gravatar sender, 500

	loadingObserve = no
