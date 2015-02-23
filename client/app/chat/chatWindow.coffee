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
		return unless event.which is 13
		content = event.target.value

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

Template.messageRow.rendered = ->
	node = $ @firstNode
	parent = $ @firstNode.parentNode

	if parent.hasClass "sticky"
		parent.scrollTop parent[0].scrollHeight

	node.find("img").tooltip
		container: "body"
		placement: if node.hasClass("own") then "right" else "left"
