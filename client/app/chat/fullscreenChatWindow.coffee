Template.fullscreenChatWindow.events
	"click .header": (e) ->
		@chatInfo.close()

		if @chatInfo.type is "private" then Router.go "personView", this
		else if @chatInfo.type is "project" then Router.go "projectView", projectId: @_id.toHexString()

	"click .closeChat": -> @chatInfo.close()

	"keyup input.messageInput": (event) ->
		content = event.target.value

		if event.which is 38
			# edit the previous message.
			@chatInfo.currentlyEditingMessage = _.findLast @chatInfo.messages(), (cm) ->
				cm.creatorId is Meteor.userId()
			event.target.value = @chatInfo.currentlyEditingMessage.content

		else if event.which is 27
			@chatInfo.close()

		else if event.which is 13 and content.trim().length > 0
			if @chatInfo.currentlyEditingMessage?
				ChatMessages.update @chatInfo.currentlyEditingMessage._id, $set:
					content: event.target.value

			else
				cm = switch @chatInfo.type
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
			@chatInfo.fetchNextPage()
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
