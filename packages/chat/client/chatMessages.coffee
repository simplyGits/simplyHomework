INACTIVE_THRESHOLD = ms.minutes 1

sub = undefined

localCount = ->
	chatRoomId = Template.currentData()._id
	ChatMessages.find(
		{ chatRoomId }
		fields: _id: 1
	).count()
hasMore = -> sub.loaded() < Counts.get 'chatMessageCount'

loadNextPage = ->
	return if sub.loading()

	$wrapper = $('#chatMessages').get 0
	previousHeight = $wrapper.scrollHeight

	sub.loadNextPage()

	loadingComp = Tracker.autorun (c) ->
		return if sub.loading()
		c.stop()
		heightDiff = $wrapper.scrollHeight - previousHeight
		$wrapper.scrollTop += heightDiff

throttledMarkRead = _.throttle ((template) ->
	if template.atBottom()
		template.data.markRead()
), 1500,
	leading: yes
	trailing: no

Template.chatMessages.helpers
	hasMore: hasMore
	isLoading: -> sub?.loading()
	newMessages: -> # TODO

Template.chatMessages.events
	"scroll div#chatMessages": (event, template) ->
		t = $ event.target

		if t.scrollTop() is 0 and hasMore()
			loadNextPage()

		else if template.atBottom() then template.sticky = yes
		else template.sticky = no

	'click .loadMore:not(.loading)': ->
		loadNextPage()

Template.chatMessages.onCreated ->
	@sticky = yes
	@subscribe 'messageCount', @data._id
	sub = Meteor.subscribeWithPagination(
		'chatMessages'
		@data._id
		ChatManager.MESSAGES_PER_PAGE
	)

Template.chatMessages.onRendered ->
	lastActive = new Date

	$messages = document.getElementById 'chatMessages'

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

	# when the user resize the window, make sure we're still scrolled to the
	# bottom
	@onWindowResize = => Meteor.defer => @sendToBottomIfNecessary()
	window.addEventListener 'resize', @onWindowResize

	# when the user makes an activity ...
	@onActivity = => Meteor.defer =>
		# update the lastActive variable ...
		lastActive = new Date
		# and mark all unread messages as read
		throttledMarkRead this
	window.addEventListener 'mousemove', @onActivity
	window.addEventListener 'keyup', @onActivity

	@autorun => # HACK
		# on a new message
		localCount()
		currentBigNotice._reactiveVar.dep.depend()

		# mark unread messages as read if the user has been active in the last 1
		# minute or we are on a phone, and the chat messages has been scrolled to
		# the bottom.
		isActive = new Date() - lastActive < INACTIVE_THRESHOLD
		if (isActive or Session.equals 'deviceType', 'phone') and @sticky
			@data.markRead()

		# go to the bottom of the screen
		Meteor.defer =>
			@sendToBottomIfNecessary()

Template.chatMessages.onDestroyed ->
	window.removeEventListener 'resize', @onWindowResize
	window.removeEventListener 'mousemove', @onActivity
	window.removeEventListener 'keyup', @onActivity

	sub.stop()

Template.messageRow.events
	'click .senderImage': ->
		$('.tooltip').tooltip 'destroy'

Template.messageRow.rendered = ->
	$node = $ @firstNode

	if Helpers.isDesktop()
		# TODO: fix this when opening multiple times.
		$node.find('[data-toggle="tooltip"]').tooltip
			container: 'body'
			placement: if $node.hasClass('own') then 'auto right' else 'auto left'
