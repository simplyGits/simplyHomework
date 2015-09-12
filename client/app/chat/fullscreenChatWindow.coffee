Template.fullscreenChatWindow.events
	"click .header": (e) ->
		@__close()

		if @__type is "private" then Router.go "personView", this
		else if @__type is "project" then Router.go "projectView", projectId: @_id.toHexString()

	"click .closeChat": -> @__close()

	"keyup input.messageInput": (event) ->
		content = event.target.value

		if event.which is 32 and (val = /\B!abbr ([a-z]+)\b/i.exec(content))?
			ga "send", "event", "abbr", "use"
			query = val[1]

			Meteor.call "http", "get", "http://tomsmeding.com/abbrgen/#{query}", (e, r) ->
				unless e?
					event.target.value = event.target.value.replace "!abbr #{query}", r.content

		else if event.which is 38
			# edit the previous message.
			@__currentlyEditingMessage = _.findLast @__messages(), (cm) ->
				cm.creatorId is Meteor.userid()
			event.target.value = @__currentlyEditingMessage.content

		else if event.which is 27
			@__close()

		else if event.which is 13 and content.trim().length > 0
			if @__currentlyEditingMessage?
				ChatMessages.update @__currentlyEditingMessage._id, $set:
					content: event.target.value

			else
				cm = switch @__type
					when "private" then new ChatMessage content, Meteor.userId(), @_id
					when "project"
						cm = new ChatMessage content, Meteor.userId(), null
						cm.projectId = @_id
						cm

				ChatMessages.insert cm

			event.target.value = ""
			_.defer -> # A lot of jQuery is pretty heavy, let's just defer it.
				x = $(event.target).closest(".fullscreenChatWindow").find(".messages")
				x.addClass "sticky"
				x.scrollTop x[0].scrollHeight

	"scroll div.messages": (event) ->
		t = $ event.target

		if t.scrollTop() is 0
			@__fetchNextPage()
		else
			if t.scrollTop() + 228 is t[0].scrollHeight then t.addClass "sticky"
			else t.removeClass "sticky"

Template.messageRow.events
	"click .senderImage": ->
		$(".fullscreenChatWindow").remove()
		$(".tooltip").tooltip "destroy"

Template.messageRow.rendered = ->
	node = $ @firstNode
	parent = $ @firstNode.parentNode

	if parent.hasClass "sticky"
		parent.scrollTop parent[0].scrollHeight

	unless Session.get "isPhone"
		node.find('[data-toggle="tooltip"]').tooltip
			container: "body"
			placement: if node.hasClass("own") then "right" else "left"
