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
		Meteor.logout()
		NotificationsManager.hideAll()
		document.location.href = 'https://simplyhomework.nl/'

# == Modals ==
addClassModalBooks = new ReactiveVar []

Template.addClassModal.helpers
	externalClasses: ->
		# TODO: remove next line.
		return externalClasses.get()

		knownIds = (info.id for info in getClassInfos())
		_.reject externalClasses.get(), (c) ->
			_.any knownIds, (id) -> EJSON.equals c._id, id

	scholierenClasses: -> ScholierenClasses.find().fetch()
	books: -> BooksHandler.engine.ttAdapter()

Template.addClassModal.events
	'click #goButton': (event) ->
		name = Helpers.cap $('#classNameInput').val()
		course = $('#courseInput').val().toLowerCase()
		bookName = $('#bookInput').val()

		Meteor.call 'insertClass', name, course, (e, classId) ->
			if e?
				notify 'Fout tijdens vak aanmaken', 'error'
			else
				Meteor.call 'insertBook', bookName, classId, (e, bookId) ->
					if e?
						notify 'Fout tijdens boek aanmaken', 'error'
					else
						Meteor.users.update Meteor.userId(), $push: classInfos:
							id: classId
							bookId: bookId

						$('#addClassModal').modal 'hide'

	'focus #bookInput': (event, template) ->
		name = Helpers.cap $('#classNameInput').val()
		template.className.set name

Template.addClassModal.onCreated ->
	@subscribe 'classes', all: yes

	@className = new ReactiveVar
	@books = new ReactiveVar []

	@autorun =>
		{ year, schoolVariant } = getCourseInfo @userId
		c = Classes.findOne
			name: @className.get()
			year: year
			schoolVariant: schoolVariant

		if c?
			books = BooksHandler.run c
			@books.set books

Template.addClassModal.onRendered ->
	Meteor.typeahead.inject '#classNameInput, #bookInput'
	Meteor.call 'getExternalClasses', (e, r) -> externalClasses.set r unless e?

Template.newSchoolYearModal.helpers classes: -> classes()

Template.newSchoolYearModal.events
	"change": (event) ->
		target = $(event.target)
		checked = target.is ":checked"
		classId = target.attr "classid"

		target.find("span").css color: if checked then "lightred" else "white"

# == End Modals ==

setMobileSettings = ->
	window.snapper = snapper = new Snap
		element: document.getElementById 'wrapper'
		minPosition: -200
		maxPosition: 200
		flickThreshold: 45
		resistance: .9
	window.closeSidebar = -> snapper.close()

setKeyboardShortcuts = ->
	Mousetrap.bind 'o', ->
		FlowRouter.go 'overview'
		no

	Mousetrap.bind 'a', ->
		FlowRouter.go 'calendar'
		no

	Mousetrap.bind 'b', ->
		FlowRouter.go 'messages'
		no

	Mousetrap.bind 'i', ->
		FlowRouter.go 'settings'
		no

	Mousetrap.bind ['/', '?'], ->
		FlowRouter.go 'overview'
		$('#searchBar > input, #searchBar .tt-input').focus()
		no

	Mousetrap.bind 'c', ->
		id = FlowRouter.getParam 'id'
		routeName = FlowRouter.getRouteName()

		if routeName is 'personView' and Meteor.userId() isnt id
			ChatManager.openPrivateChat id
		else if routeName is 'classView'
			ChatManager.openClassChat id
		else
			$('.searchBox > input').focus()
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

	Mousetrap.bind ['ctrl+/', 'command+/', 'ctrl+?', 'command+?'], ->
		alertModal(
			'Toetsenbord shortcuts'
			Locals['nl-NL'].KeyboardShortcuts()
			DialogButtons.Ok
			{ main: 'Sluiten' }
			{ main: 'btn-primary' }
		)
		no

Template.app.helpers
	pageColor: -> Session.get("pageColor") ? "lightgray"
	pageTitle: -> Session.get("headerPageTitle") ? ""
	unreadChatCount: ->
		roomIds = ChatRooms.find({}, { fields: _id: 1 }).map (r) -> r._id
		messages = ChatMessages.find({
			creatorId: $ne: Meteor.userId()
			readBy: $ne: Meteor.userId()
			chatRoomId: $in: roomIds
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
	chat: ->
		ChatRooms.findOne {
			_id: FlowRouter.getQueryParam('openChatId')
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
	mailVerified = Meteor.user().emails[0].verified
	if not mailVerified and
	Helpers.daysRange(Meteor.user().createdAt, new Date(), no) >= 2
		notify '''
			Je hebt je account nog niet geverifiëerd.
			Check je email!
		''', 'warning'

	@autorun ->
		dateTracker.depend()
		now = new Date
		birthDate = getUserField Meteor.userId(), 'profile.birthDate'
		event = getEvent 'congratulated'

		if birthDate? and Helpers.datesEqual(now, birthDate) and
		event?.getUTCFullYear() isnt now.getUTCFullYear()
			swalert
				title: 'Gefeliciteerd!'
				text: "Gefeliciteerd met je #{moment().diff val, 'years'}e verjaardag!"
			Meteor.call 'markUserEvent', 'congratulated'

	@autorun ->
		# Disabled for now. It isn't working probably, and heck, we should even
		# refactor it too, since the logic now spans 3 files in unlogical places.
		return undefined
		if Meteor.status().connected and Meteor.userId()? and not has 'noAds'
			setTimeout (-> Meteor.defer ->
				unless Session.get 'adsAllowed'
					App.logout()
					swalert
						title: 'Adblock :c'
						html: '''
							Om simplyHomework gratis beschikbaar te kunnen houden zijn we afhankelijk van reclame-inkomsten.
							Om simplyHomework te kunnen gebruiken, moet je daarom je AdBlocker uitzetten.
							Wil je simplyHomework toch zonder reclame gebruiken, dan kan je <a href="/">premium</a> nemen.
						'''
						type: 'error'
			), 3000

	# REVIEW: Maybe use a cleaner method using Blaze and stuff?
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
	setKeyboardShortcuts()

	if Session.equals 'deviceType', 'desktop'
		# `startMonitor` will throw an error when the time isn't synced yet, when
		# the time is done syncing the current computation will invalidate, so to
		# effectively enable the monitor ASAP we put it inside of an `autorun` and a
		# `try`.
		@autorun -> try UserStatus.startMonitor idleOnBlur: yes
	else
		setMobileSettings()

	if not getEvent('cookiesNotice')? and
	$('#cookiesContainer').length is 0
		Blaze.render Template.cookies, document.body
		$cookiesContainer = $ '#cookiesContainer'

		$cookiesContainer
			.addClass 'visible'

			.find 'button'
			.click ->
				Meteor.call 'markUserEvent', 'cookiesNotice'
				$cookiesContainer
					.removeClass 'visible'
					.on 'transitionend webkitTransitionEnd oTransitionEnd', ->
						$(this).remove()
