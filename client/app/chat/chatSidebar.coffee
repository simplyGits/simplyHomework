searchTerm = new ReactiveVar ""

Template.chatSidebar.events
	"keyup input": (event) ->
		if event.which is 27
			$("div.searchBox > input").blur()
			return
		else if event.which is 13
			searchTerm.set event.target.value = ""
			# >>> OPEN CHAT FOR FIRST SEARCH RESULT <<<
			return

		searchTerm.set event.target.value

Template.chatSidebar.helpers
	chats: ->
		caseInsensitive = searchTerm.get() is searchTerm.get().toLowerCase()

		calcDistance = null
		if caseInsensitive
			calcDistance = _.curry (s) -> DamerauLevenshtein(insert: 0)(searchTerm.get().trim().toLowerCase(), s.trim().toLowerCase())
		else
			calcDistance = _.curry (s) -> DamerauLevenshtein(insert: 0)(searchTerm.get().trim(), s.trim())

		users = Meteor.users.find({ _id: $ne: Meteor.userId() }, transform: (u) ->
			return _.extend u,
				__initial: null
				__sidebarIcon: gravatar u

				__status: (
					if u.status.idle then "inactive"
					else if u.status.online then "online"
					else "offline"
				)
				__friendlyName: "#{u.profile.firstName} #{u.profile.lastName}"

				__unreadMessagesCount: -> ChatMessages.find({ creatorId: u._id, to: Meteor.userId(), readBy: $ne: Meteor.userId() }).count()

				__topMessages: 10
				__fetchNextPage: -> Meteor.subscribe "chatMessages", { userId: u._id }, @__topMessages += 10
				__messages: -> ChatMessages.find({ $or: [ { to: u._id }, { creatorId: u._id } ] }, sort: "time": -1).fetch()
		).fetch()

		projects = Projects.find({}, sort: { "deadline": 1, "name": 1 }, transform: (p) ->
			return _.extend p,
				__initial: p.name[0].toUpperCase()
				__sidebarIcon: null

				__status: ""
				__friendlyName: p.name

				__unreadMessagesCount: -> ChatMessages.find({ creatorId: { $ne: Meteor.userId() }, projectId: p._id, readBy: $ne: Meteor.userId() }).count()

				__topMessages: 10
				__fetchNextPage: -> Meteor.subscribe "chatMessages", { projectId: p._id }, @__topMessages += 10
				__messages: -> ChatMessages.find({ projectId: p._id }, sort: "time": -1).fetch()
		).fetch()

		groups = [] # Later when we implement groups.

		return _(users.concat(projects).concat(groups))
			.filter (chat) -> searchTerm.get().trim() is "" or calcDistance(chat.__friendlyName) < 2 or Helpers.contains chat.__friendlyName, searchTerm.get(), caseInsensitive
			.sortBy (chat) ->
				if searchTerm.get().trim() is ""
					return chat.__lastInteraction
				else
					distance = DamerauLevenshtein()(searchTerm.get().trim().toLowerCase(), chat.__friendlyName.trim().toLowerCase())

					trimmed = chat.__friendlyName.trim().toLowerCase()
					# If the name contains a word beginning with the query; lower distance a substensional amount.
					if (index = trimmed.indexOf searchTerm.get().trim().toLowerCase()) is 0 or trimmed[index - 1] is " " then distance -= 10

					return distance
			.value()

Template.chatSidebar.rendered = ->
	stayOpen = no

	# Attach classes to body on chatSidebar hover / blur
	$("div.chatSidebar").hover (->
		$("body").addClass "chatSidebarOpen"
	), (->
		return if stayOpen
		$("body").removeClass "chatSidebarOpen"

		searchTerm.set ""
		$("div.searchBox > input").val ""
	)

	$("div.searchBox > input") # ChatSidebar fix handeling for searchBox.
		.focus ->
			stayOpen = yes
			$("body").addClass "chatSidebarOpen"
		.blur ->
			stayOpen = no
			$("body").removeClass "chatSidebarOpen"

			searchTerm.set ""
			$("div.searchBox > input").val ""
