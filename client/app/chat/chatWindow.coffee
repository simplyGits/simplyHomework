Template.mobileChatWindow.helpers
	bottomOffset: -> "#{if has("noAds") then 0 else 90}px"

Template.mobileChatWindow.events
	"click div.header": ->
		if @chatInfo.type is "private" then Router.go "personView", this
		else if @chatInfo.type is "project" then Router.go "projectView", projectId: @_id.toHexString()

	"keyup input.messageInput": (event) ->
		content = event.target.value

		if event.which is 13 and content.trim().length > 0
			ChatMessages.insert switch @chatInfo.type
				when "private"
					new ChatMessage content, Meteor.userId(), @_id
				when "project"
					cm = new ChatMessage content, Meteor.userId(), null
					cm.projectId = @_id
					cm

			$('input.messageInput').val ''
			Meteor.defer -> # A lot of jQuery is pretty heavy, let's just defer it.
				x = $('.messages').addClass 'sticky'
				x.scrollTop x[0].scrollHeight

	"scroll div.messages": (event) ->
		t = $ event.target

		if t.scrollTop() is 0
			@chatInfo.fetchNextPage()
		else
			if t.scrollTop() + 228 is t[0].scrollHeight then t.addClass "sticky"
			else t.removeClass "sticky"
