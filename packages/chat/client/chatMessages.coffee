MESSAGE_PER_PAGE = 40
sub = undefined

localCount = ->
	chatRoomId = Template.currentData()._id
	ChatMessages.find(
		{ chatRoomId }
		fields: _id: 1
	).count()
hasMore = -> sub.loaded() < Counts.get 'chatMessageCount'

throttledMarkRead = _.throttle ((template) ->
	if template.atBottom()
		console.log 'marking all messages as read, chatroom:', template.data
		template.data.markRead()
), 1500,
	leading: yes
	trailing: no

Template.chatMessages.helpers
	hasMore: hasMore
	isLoading: -> sub?.loading()
	messages: ->
		ChatMessages.find {
			chatRoomId: @_id
		}, {
			sort: 'time': 1
		}
	newMessages: -> # TODO

Template.chatMessages.events
	"scroll div#chatMessages": (event, template) ->
		t = $ event.target

		if t.scrollTop() is 0 and hasMore()
			$wrapper = $('#chatMessages').get 0
			previousHeight = $wrapper.scrollHeight

			sub.loadNextPage()

			Tracker.autorun (c) ->
				return if sub.loading()
				c.stop()
				heightDiff = $wrapper.scrollHeight - previousHeight
				$wrapper.scrollTop += heightDiff

		else if template.atBottom() then template.sticky = yes
		else template.sticky = no

Template.chatMessages.onCreated ->
	@sticky = yes
	@subscribe 'messageCount', @data._id
	sub = Meteor.subscribeWithPagination(
		'chatMessages'
		@data._id
		MESSAGE_PER_PAGE
	)

Template.chatMessages.onRendered ->
	$messages = $('#chatMessages').get 0

	@atBottom = -> $messages.scrollTop >= $messages.scrollHeight - $messages.clientHeight

	# SUPER HACKY
	window.sendToBottom =
	@sendToBottom = =>
		$messages.scrollTop = $messages.scrollHeight - $messages.clientHeight
		@sticky = yes

	@sendToBottomIfNecessary = _.debounce =>
		if @sticky and not @atBottom()
			@sendToBottom()
	, 10
	@sendToBottomIfNecessary()

	@autorun =>
		localCount()
		currentBigNotice._reactiveVar.dep.depend()
		@sendToBottomIfNecessary()

	@onWindowResize = => Meteor.defer => @sendToBottomIfNecessary()
	window.addEventListener 'resize', @onWindowResize

	@markRead = => Meteor.defer => throttledMarkRead this
	window.addEventListener 'mousemove', @markRead
	window.addEventListener 'keyup', @markRead

Template.chatMessages.onDestroyed ->
	window.removeEventListener 'resize', @onWindowResize
	window.removeEventListener 'mousemove', @markRead
	window.removeEventListener 'keyup', @markRead

Template.messageRow.events
	"click .senderImage": ->
		ChatManager.closeChat()
		$(".tooltip").tooltip "destroy"

Template.messageRow.rendered = ->
	$node = $ @firstNode

	if Session.equals 'deviceType', 'desktop'
		# TODO: fix this when opening multiple times.
		$node.find('[data-toggle="tooltip"]').tooltip
			container: 'body'
			placement: if $node.hasClass('own') then 'auto right' else 'auto left'
