Template.chatWindow.events
	"click .chatWindow": (event) ->
		$(event.currentTarget).find("input").focus()
		@__markRead()

	"click img.profilePicture, click div.name": (e) ->
		# close sidebar.
		if @__type is "private" then Router.go "personView", @
		else if @__type is "project" then Router.go "projectView", projectId: @_id.toHexString()

	"click .fa-times": -> @__close()

	"keyup input.messageInput": (event) ->
		content = event.target.value
		return unless event.which is 13 and content.trim().length > 0

		cm = switch @__type
			when "private" then new ChatMessage content, Meteor.userId(), @_id
			when "project"
				cm = new ChatMessage content, Meteor.userId(), null
				cm.projectId = @_id
				cm

		ChatMessages.insert cm
		event.target.value = ""

		_.defer -> # A lot of jQuery is pretty heavy, let's just defer it.
			x = $(event.target).closest(".chatWindow").find(".messages")
			x.addClass "sticky"
			x.scrollTop x[0].scrollHeight

	"scroll div.messages": (event) ->
		t = $ event.target

		if t.scrollTop() is 0
			@__fetchNextPage()
		else
			if t.scrollTop() + 228 is t[0].scrollHeight then t.addClass "sticky"
			else t.removeClass "sticky"

Template.mobileChatWindow.helpers "bottomOffset": -> "#{if has("noAds") then 0 else 90}px"

Template.mobileChatWindow.events
	"click div.header": ->
		if @__type is "private" then Router.go "personView", @
		else if @__type is "project" then Router.go "projectView", projectId: @_id.toHexString()

	"keyup input.messageInput": (event) ->
		content = event.target.value
		return unless event.which is 13 and content.trim().length > 0

		cm = switch @__type
			when "private" then new ChatMessage content, Meteor.userId(), @_id
			when "project"
				cm = new ChatMessage content, Meteor.userId(), null
				cm.projectId = @_id
				cm

		ChatMessages.insert cm
		event.target.value = ""

		_.defer -> # A lot of jQuery is pretty heavy, let's just defer it.
			x = $(event.target).closest(".mobileChatWindow").find(".messages")
			x.addClass "sticky"
			x.scrollTop x[0].scrollHeight

	"scroll div.messages": (event) ->
		t = $ event.target

		if t.scrollTop() is 0
			@__fetchNextPage()
		else
			if t.scrollTop() + 228 is t[0].scrollHeight then t.addClass "sticky"
			else t.removeClass "sticky"

Template.messageRow.rendered = ->
	node = $ @firstNode
	parent = $ @firstNode.parentNode

	if parent.hasClass "sticky"
		parent.scrollTop parent[0].scrollHeight

	unless Session.get "isPhone"
		node.find("img").tooltip
			container: "body"
			placement: if node.hasClass("own") then "right" else "left"
