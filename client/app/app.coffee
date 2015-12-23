schoolSub = null
externalClasses = new ReactiveVar()
externalAssignments = new ReactiveVar()
@currentBigNotice = new SReactiveVar Match.OneOf(null, Object), null

###*
# @class App
###
class @App
	@logout: ->
		FlowRouter.go 'launchPage'
		Meteor.defer ->
			Meteor.logout()
			NotificationsManager.hideAll()

	@runTour: ->
		FlowRouter.go 'overview'

		# TODO: Remake tour.
		tour = null
		tour = new Shepherd.Tour
			defaults:
				classes: 'shepherd-theme-arrows'
				scrollTo: true
				buttons: [
					{
						text: "terug"
						action: -> tour.back arguments...
					}
					{
						text: "verder"
						action: -> tour.next arguments...
					}
				]

		tour.addStep
			text: "Dit is de sidebar, hier kun je op een simpele manier overal komen."
			attachTo: ".sidebar"
			buttons: [
				{
					text: "verder"
					action: -> tour.next arguments...
				}
			]

		tour.addStep
			text: "Dit ben jij, als je op jezelf klikt zie je je profiel."
			attachTo: ".sidebarProfile"

		tour.addStep
			text: "Dit is het overzicht, in principe staat hier alles wat je nodig hebt."
			attachTo: "div.sidebarButton#overview"

		tour.addStep
			text: "Hier staan je taken voor vandaag, als je deze af hebt gewerkt ben je klaar."
			attachTo: "div#overviewTaskContainer"

		tour.addStep
			text: "Hier staan je projecten. Je kunt een nieuwe aanmaken door op het plusje te klikken."
			attachTo: "div#overviewProjectContainer"

		tour.addStep
			text: "Dit is je agenda, hij is slim en overzichtelijk."
			attachTo: "div.sidebarButton#calendar"

		tour.addStep
			text: "Wil je alles van een bepaald vak zien? Klik op de naam en krijg een mooi overzicht."
			attachTo: "div.sidebarClasses"

		tour.addStep
			text: "Hier vind je alle opties van simplyHomework. Je kunt gegevens aanpassen en de planner personaliseren."
			attachTo: "div.sidebarFooterSettingsIcon"

		tour.addStep "calendar",
			text: "Dit is je agenda. Dubbel klik op een lege plek om een afspraak toe te voegen."

		tour.addStep "calendar",
			text: "Hier kun je afspraken toevoegen aan je agenda en navigeren tussen de weken"
			attachTo: "div.fc-right"

		tour.on "show", (o) ->
			FlowRouter.go (
				switch o.step.id
					when 'calendar' then 'calendar'
					else 'app'
			)

			$(".tour-current-active").removeClass "tour-current-active"
			$(o.step.options.attachTo).addClass "tour-current-active"

		tour.on "complete", ->
			FlowRouter.go 'overview'

			swalert
				title: "Dit was de tour!"
				text: "Veel success! Als je hulp nodig hebt kun je altijd via de instellingen deze tour opnieuw doen."
				type: "success"

			Mousetrap.unbind ["escape", "left", "right"]

		tour.start()

		_.defer ->
			$("div.backdrop").one "click", tour.cancel

			Mousetrap.bind "escape", tour.cancel
			Mousetrap.bind "left", ->
				if tour.currentStep.id is "step-0" then tour.cancel()
				else tour.back()
			Mousetrap.bind "right", tour.next

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
	books: -> addClassModalBooks.get()

Template.addClassModal.events
	"click #goButton": (event) ->
		name = Helpers.cap $("#classNameInput").val()
		course = $("#courseInput").val().toLowerCase()
		bookName = $("#bookInput").val()
		{ year, schoolVariant } = getCourseInfo()

		classId = undefined
		_class = Classes.findOne
			$or: [
				{ name: $regex: name, $options: 'i' }
				{ abbreviations: course.toLowerCase() }
			]
			schoolVariant: schoolVariant
			year: year
		if _class? then classId = _class._id
		else
			scholierenClass = ScholierenClasses.findOne ->
				@name
					.toLowerCase()
					.indexOf(name.toLowerCase()) > -1

			_class = new SchoolClass(
				name,
				course,
				year,
				schoolVariant
			)
			_class.scholierenClassId = scholierenClassId?.id
			classId = Classes.insert _class, Debug.logArgs

		book = Books.findOne title: bookName
		unless book? or bookName.trim() is ''
			book = new Book bookName, undefined, @id, undefined, _class._id
			Books.insert book

		Meteor.users.update Meteor.userId(), $push: classInfos:
			id: classId
			bookId: book?._id

		$("#addClassModal").modal "hide"

	'focus #bookInput': ->
		name = Helpers.cap $('#classNameInput').val()

		{ year, schoolVariant } = getCourseInfo()
		classId = Classes.findOne({ name, year, schoolVariant })?._id
		books = Books.find({ classId }).fetch()

		scholierenClass = ScholierenClasses.findOne -> Helpers.contains @name, name, yes
		books = _(scholierenClass?.books)
			.reject (b) -> b.title in ( x.title for x in books )
			.concat books
			.value()

		addClassModalBooks.set books

Template.addClassModal.onCreated ->
	@subscribe 'scholieren.com'
	@subscribe 'classes', all: yes

Template.addClassModal.onRendered ->
	Meteor.typeahead.inject '#classNameInput, #bookInput'

	Meteor.call 'getExternalClasses', (e, r) -> externalClasses.set r unless e?

Template.addClassModal.onDestroyed ->
	addClassModalBooks.set []

Template.newSchoolYearModal.helpers classes: -> classes()

Template.newSchoolYearModal.events
	"change": (event) ->
		target = $(event.target)
		checked = target.is ":checked"
		classId = target.attr "classid"

		target.find("span").css color: if checked then "lightred" else "white"

Template.addProjectModal.helpers
	assignments: ->
		externalAssignments.get()?.map (a) ->
			_class = -> Classes.findOne a.classId
			_.extend a,
				__project: -> Projects.findOne externalId: a.externalId
				__class: _class
				__abbreviation: -> _class().abbreviations[0]

	classes: -> classes()
	selected: (event, _class) -> Session.set 'currentSelectedClassDatum', _class

Template.addProjectModal.events
	'click #createButton': ->
		project = new Project(
			@name,
			@description,
			@deadline,
			Meteor.userId(),
			@classId,
			{
				id: @externalId
				fetchedBy: @fetchedBy
				name: @name
			}
		)
		Projects.insert project
		$('#addProjectModal').modal 'hide'

	'click .goToProjectButton': (event) ->
		FlowRouter.go 'projectView', id: @__project._id
		$('#addProjectModal').modal 'hide'

	'click #goButton': ->
		name = $('#addProjectModal #nameInput').val().trim()
		description = $('#addProjectModal #descriptionInput').val().trim()
		deadline = $('#addProjectModal #deadlineInput').data('DateTimePicker').date().toDate()
		classId = Session.get('currentSelectedClassDatum')?._id

		return if name is ''
		if Projects.findOne({ name })?
			setFieldError '#projectNameGroup', 'Je hebt al een project met dezelfde naam'
			return

		if not classId? and $('#addProjectModal #classNameInput').val().trim() isnt ''
			shake '#addProjectModal'
			return

		project = new Project(
			name,
			description,
			deadline,
			Meteor.userId(),
			classId,
			null
		)
		Projects.insert project

		$('#addProjectModal').modal 'hide'

Template.addProjectModal.onRendered ->
	Meteor.typeahead.inject '#classNameInput'

	$('#deadlineInput').datetimepicker
		locale: moment.locale()
		defaultDate: new Date()
		icons:
			time: 'fa fa-clock-o'
			date: 'fa fa-calendar'
			up: 'fa fa-arrow-up'
			down: 'fa fa-arrow-down'
			previous: 'fa fa-chevron-left'
			next: 'fa fa-chevron-right'

	Meteor.call 'getExternalAssignments', (e, r) ->
		externalAssignments.set r unless e?

# == End Modals ==

# == Sidebar ==

Template.sidebar.onCreated ->
	@autorun =>
		# We have to depend on the user's classInfos since the publishment isn't
		# reactive. This will make the publishment run again with the added classes.
		@subscribe 'classes' unless _.isEmpty getClassInfos()

Template.sidebar.helpers
	'classes': -> classes()

Template.sidebar.events
	'click .sidebarFooterSettingsIcon': -> FlowRouter.go 'settings'
	'click #addClassButton': -> showModal 'addClassModal'

# == End Sidebar ==

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
		alertModal 'Toetsenbord shortcuts', Locals['nl-NL'].KeyboardShortcuts(), DialogButtons.Ok, { main: 'Sluiten' }, { main: 'btn-primary' }
		no

Template.app.helpers
	pageColor: -> Session.get("pageColor") ? "lightgray"
	pageTitle: -> Session.get("headerPageTitle") ? ""

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
	# TODO: REFACTOR THE SHIT OUT OF THIS.
	###
	mailVerified = Meteor.user().emails[0].verified
	if not mailVerified and
	Helpers.daysRange(Meteor.user().createdAt, new Date(), no) >= 2
		notify '''
			Je hebt je account nog niet geverifiëerd.
			Check je email!
		''', 'warning'
	###

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

	###
	@autorun ->
		return unless Meteor.userId()?
		lastUpdate = Meteor.user().profile.courseInfo.classGroupsUpdated
		start = new Date
		end = new Date().addDays 7

		if lastUpdate? and
		_.now() - lastUpdate.getTime() < 1000 * 60 * 60 * 24 # 24 hours
			return

		Meteor.subscribe 'externalCalendarItems', start, end

		classGroups = Meteor.user().profile.courseInfo.classGroups
		return unless classGroups?

		res = []
		for classInfo in Meteor.user().classInfos
			group = CalendarItems.findOne(
				classId: classInfo.id
				description:
					$exists: yes
					$ne: ''
			)?.description
			continue unless group?

			classGroup = _.find(classGroups, (i) -> i.id is classInfo.id) ? {}
			res.push _.extend classGroup, group

		Meteor.users.update Meteor.userId(), $set:
			'profile.courseInfo.classGroups': res
			'profile.courseInfo.classGroupsUpdated': new Date
	###

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
