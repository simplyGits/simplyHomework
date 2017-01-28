import Privacy from 'meteor/privacy'
import SReactiveVar from 'meteor/simply:strict-reactive-var'
import { isDesktop, isPhone } from 'meteor/device-type'

schoolSub = null
externalClasses = new ReactiveVar()
@currentBigNotice = new SReactiveVar Match.OneOf(null, Object), null

###*
# @class App
# @static
###
class @App
	###*
	# @method logout
	###
	@logout: ->
		ga 'send', 'event', 'logout'
		Meteor.logout()
		NotificationsManager.hideAll()

# == Modals ==
Template.newSchoolYearModal.helpers classes: -> classes()

Template.newSchoolYearModal.events
	"change": (event) ->
		target = $(event.target)
		checked = target.is ":checked"
		classId = target.attr "classid"

		target.find("span").css color: if checked then "lightred" else "white"

Template.addTicketModal.helpers
	body: -> Session.get('addTicketModalContent') ? ''

Template.addTicketModal.events
	'keyup': ->
		body = $('#ticketBodyInput').val()
		Session.set 'addTicketModalContent', body

	'click #sendButton': ->
		body = $('#ticketBodyInput').val()
		$modal = $ '#addTicketModal'

		Meteor.call 'insertTicket', body, (e, r) ->
			if e?
				notify (
					switch e.error
						when 'empty-body' then 'Inhoud kan niet leeg zijn'
						else 'Onbekende fout, we zijn op de hoogte gesteld'
				), 'error'
				shake $modal
			else
				notify 'Ticket aangemaakt', 'success'
				$modal.modal 'hide'
				Session.set 'addTicketModalContent', ''

# == End Modals ==

setSnapper = ->
	window.snapper?.disable()
	window.snapper = new Snap
		element: document.getElementById 'wrapper'
		minPosition: -200
		maxPosition: 200
		flickThreshold: 45
		resistance: .9
	window.closeSidebar = -> window.snapper.close()

setKeyboardShortcuts = ->
	Mousetrap.bind 'g o', ->
		FlowRouter.go 'overview'
		no

	Mousetrap.bind 'g a', ->
		FlowRouter.go 'calendar'
		no

	Mousetrap.bind ['g b', 'g m'], ->
		FlowRouter.go 'messages'
		no

	Mousetrap.bind ['g i', 'g s'], ->
		FlowRouter.go 'settings'
		no

	Mousetrap.bind '/', ->
		FlowRouter.go 'overview'
		$('#searchBar > input, #searchBar .tt-input').focus()
		no

	Mousetrap.bind 'c', ->
		$('.searchBox > input').focus()
		no

	Mousetrap.bind 'g c', ->
		id = FlowRouter.getParam 'id'
		routeName = FlowRouter.getRouteName()

		if routeName is 'personView' and Meteor.userId() isnt id
			ChatManager.openPrivateChat id
		else if routeName is 'classView'
			ChatManager.openClassChat id
		else if routeName is 'projectView'
			ChatManager.openProjectChat id
		no

	buttonGoto = (delta) ->
		buttons = $('.sidebarButton').get()
		oldIndex = buttons.indexOf $('.sidebarButton.selected').get 0
		index = (oldIndex + delta) % buttons.length

		id = buttons[if index is -1 then buttons.length - 1 else index].id
		switch id
			when 'overview' then FlowRouter.go 'overview'
			when 'calendar' then FlowRouter.go 'calendar'
			when 'messages' then FlowRouter.go 'messages'
			else FlowRouter.go 'classView', { id }

	Mousetrap.bind ['shift+up', 'shift+k'], ->
		buttonGoto -1
		no

	Mousetrap.bind ['shift+down', 'shift+j'], ->
		buttonGoto 1
		no

	Mousetrap.bind ['ctrl+/', 'command+/', 'ctrl+?', 'command+?', '?'], ->
		alertModal(
			'Toetsenbord shortcuts'
			TAPi18n.__ 'keyboardShortcuts'
			DialogButtons.Ok
			{ main: 'Sluiten' }
			{ main: 'btn-primary' }
		)
		no

Template.app.helpers
	pageColor: -> Session.get("pageColor") ? "lightgray"
	pageTitle: -> Session.get("headerPageTitle") ? ""
	unreadChatCount: ->
		messages = ChatMessages.find({
			creatorId: $ne: Meteor.userId()
			readBy: $ne: Meteor.userId()
		}, {
			transform: null
			fields:
				chatRoomId: 1
				readBy: 1
				creatorId: 1
		}).fetch()

		_.uniq(messages, 'chatRoomId').length

	showAdbar: ->
		excluded = [
			'mobileChat'
		]
		not has('noAds') and FlowRouter.getRouteName() not in excluded
	runningSetup: -> Session.get 'runningSetup'
	bootstrapping: -> getEvent('bootstrapping')?
	chat: ->
		if not isPhone() and
		FlowRouter.getRouteName() is 'chat'
			ChatRooms.findOne {
				_id: FlowRouter.getParam 'id'
			}, {
				fields:
					lastMessageTime: 0
			}

	currentBigNotice: -> currentBigNotice.get()

Template.app.events
	'click .headerIcon': (event) ->
		if window.snapper.state().state is 'closed'
			window.snapper.open event.target.dataset.snapSide
		else
			window.snapper.close()
	'click #title': -> $('.content').stop().animate scrollTop: 0

	'click #bigNotice > #content': -> currentBigNotice.get().onClick? arguments...
	'click #bigNotice > #dismissButton': -> currentBigNotice.get().onDismissed? arguments...

Template.app.onCreated ->
	@autorun ->
		mailVerified = getUserField Meteor.userId(), 'emails[0].verified'
		createdAt = getUserField Meteor.userId(), 'createdAt'

		if mailVerified? and
		not mailVerified and
		Helpers.daysRange(createdAt, new Date(), no) >= 2
			notify '''
				Je hebt je account nog niet geverifiëerd.
				Check je email!
			''', 'warning'

	@autorun -> App.logout() unless Meteor.userId()? or Meteor.loggingIn()

	@autorun ->
		events = getUserField Meteor.userId(), 'events'
		return unless events?

		dateTracker.depend()
		now = new Date
		birthDate = getUserField Meteor.userId(), 'profile.birthDate'
		event = events.congratulated

		if birthDate? and Helpers.datesEqual(now, birthDate) and
		event?.getFullYear() isnt now.getFullYear()
			Meteor.defer ->
				Meteor.call 'markUserEvent', 'congratulated'

			swalert
				title: 'Gefeliciteerd!'
				text: "Gefeliciteerd met je #{moment().diff birthDate, 'years'}e verjaardag!"

	# REVIEW: Maybe use a cleaner method using Blaze and stuff?
	# TODO: move this in the 'notices' packages
	notifmap = {}
	notifications = Notifications.find(
		userIds: Meteor.userId()
		done: $ne: Meteor.userId()
	).observe
		added: (doc) ->
			notifmap[doc._id] = NotificationsManager.notify
				body: doc.content
				# REVIEW: Make sure we're escaping userdata in notifications correctly
				# everywhere.
				html: yes
				dismissable: doc.dismissable
				type: doc.type
				time: doc.time
				image: switch doc.topic?.type
					when 'person' then picture doc.topic.id, 500
					else doc.image
				priority: doc.priority
				onClick: ->
					# TODO: ehm yeah ehm, do some action..? ^^'
					Meteor.call 'markNotificationRead', doc._id, yes
				onDismissed: ->
					Meteor.call 'markNotificationRead', doc._id, no
		changed: (newdoc, olddoc) ->
			if newdoc.content isnt olddoc.content
				notifmap[doc._id].content newdoc.content, yes
		removed: (doc) ->
			notifmap[doc._id].hide()
			delete notifmap[doc._id]

Template.app.onRendered ->
	setSnapper()
	setKeyboardShortcuts()

	@autorun ->
		try
			if isDesktop()
				window.snapper.close()
				window.snapper.disable()
			else
				window.snapper.enable()

	if isDesktop()
		# `startMonitor` will throw an error when the time isn't synced yet, when
		# the time is done syncing the current computation will invalidate, so to
		# effectively enable the monitor ASAP we put it inside of an `autorun` and a
		# `try`.
		@autorun ->
			if Privacy.getOptions(Meteor.userId()).publishStatus
				try UserStatus.startMonitor idleOnBlur: yes
			else if UserStatus.isMonitoring()
				UserStatus.stopMonitor()
