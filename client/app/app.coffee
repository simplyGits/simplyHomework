schoolSub = null
addClassComp = null
externalClasses = new SReactiveVar SchoolClass, null
@currentBigNotice = new SReactiveVar Match.OneOf(null, Object), null

###*
# @class App
###
class @App
	###*
	# @method showModal
	# @param name {String} The ID of the modal, has to be the same as the template name.
	# @param [options] {Object}
	# @return {Function} When called, removes the newely spawned modal.
	###
	@showModal: (name, options) ->
		check name, String
		check options, Match.Optional Object

		view = Blaze.render Template[name], document.body
		$modal = $ "##{name}"
		$modal
			.modal options
			.on 'hidden.bs.modal', -> Blaze.remove view

		-> $modal.modal 'hide'

	@runTour: ->
		Router.go "app"

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
			Router.go (switch o.step.id
				when "calendar" then "calendar"
				else "app"
			)

			$(".tour-current-active").removeClass "tour-current-active"
			$(o.step.options.attachTo).addClass "tour-current-active"

		tour.on "complete", ->
			Router.go "app"

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

# == Bloodhounds ==

bookEngine = new Bloodhound
	name: "books"
	datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.title
	queryTokenizer: Bloodhound.tokenizers.whitespace
	local: []

classEngine = new Bloodhound
	name: "classes"
	datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.name
	queryTokenizer: Bloodhound.tokenizers.whitespace
	local: []

# == End Bloodhounds ==

# == Modals ==

Template.addClassModal.events
	"click #goButton": (event) ->
		name = Helpers.cap $("#classNameInput").val()
		course = $("#courseInput").val().toLowerCase()
		bookName = $("#bookInput").val()
		color = $("#colorInput").val()
		{ year, schoolVariant } = Meteor.user().profile.courseInfo

		_class = Classes.findOne { $or: [{ name: name }, { course: course }], schoolVariant: schoolVariant, year: year}
		_class ?= New.class name, course, year, schoolVariant, ScholierenClasses.findOne(-> @name.toLowerCase().indexOf(name.toLowerCase()) > -1).id

		book = Books.findOne title: bookName
		unless book? or bookName.trim() is ""
			book = New.book bookName, undefined, @id, undefined, _class._id

		Meteor.users.update Meteor.userId(), $push: classInfos:
			id: _class._id
			color: color
			bookId: book._id

		$("#addClassModal").modal "hide"
		addClassComp.stop()

	"keyup #classNameInput, #courseInput": (event) ->
		val = Helpers.cap $("#classNameInput").val()

		{ year, schoolVariant } = Meteor.user().profile.courseInfo
		classId = Classes.findOne({_name: val, schoolVariant: schoolVariant, year: year})?._id

		books = Books.find({ classId }).fetch()

		scholierenClass = ScholierenClasses.findOne -> @name.toLowerCase().indexOf(val.toLowerCase()) > -1
		books.pushMore _.filter scholierenClass?.books, (b) -> not _.contains ( x.title for x in books ), b.title

		bookEngine.clear()
		bookEngine.add books

Template.addClassModal.rendered = ->
	$("#colorInput").colorpicker color: "#333"
	$("#colorInput").on "changeColor", -> $("#colorLabel").css color: $("#colorInput").val()

	bookEngine.initialize()
	classEngine.initialize()

	$("#bookInput").typeahead(null,
		source: bookEngine.ttAdapter()
		displayKey: "title"
	).on "typeahead:selected", (obj, datum) -> obj.__method = datum

	$("#classNameInput").typeahead null,
		source: classEngine.ttAdapter()
		displayKey: "name"

	Meteor.call 'getExternalClasses', (e, r) -> externalClasses.set r unless e?

Template.settingsModal.events
	'click button': -> $('#settingsModal').modal 'hide'
	'click #schedularPrefsButton': -> App.showModal 'plannerPrefsModal'
	'click #accountInfoButton': -> App.showModal 'accountInfoModal'
	'click #deleteAccountButton': -> App.showModal 'deleteAccountModal'
	'click #startTourButton': -> App.runTour()
	'click #logOutButton': -> App.logout()

Template.deleteAccountModal.events
	"click #goButton": ->
		input = $ "#deleteAccountModal #passwordInput"
		captcha = $("#g-recaptcha-response").val()

		pass = Package.sha.SHA256 input.val()
		Meteor.call "removeAccount", pass, captcha, (e) ->
			if e.error is "wrongPassword"
				setFieldError input, "Verkeerd wachtwoord"
				grecaptcha.reset()
			else if e.error is "wrongCaptcha"
				shake "#deleteAccountModal"
			else ga "send", "event", "action", "remove", "account"

Template.newSchoolYearModal.helpers classes: -> classes()

Template.newSchoolYearModal.events
	"change": (event) ->
		target = $(event.target)
		checked = target.is ":checked"
		classId = target.attr "classid"

		target.find("span").css color: if checked then "lightred" else "white"

Template.accountInfoModal.helpers currentMail: -> Meteor.user().emails[0].address

Template.accountInfoModal.events
	"click #goButton": ->
		mail = $("#mailInput").val().toLowerCase()

		firstName = Helpers.nameCap $("#firstNameInput").val()
		lastName = Helpers.nameCap $("#lastNameInput").val()

		oldPass = $("#oldPassInput").val()
		newPass = $("#newPassInput").val()

		profile = Meteor.user().profile

		###*
		# Shows success / error message to the user.
		# @method callback
		# @param success {Boolean|null} If true show a success message, otherwise show an error message. If null, no message will be shown at all.
		###
		callback = (success) ->
			if success
				swalert
					title: ":D"
					text: "Je aanpassingen zijn successvol opgeslagen"
					type: "success"
			else if success is no # sounds like sombody who sucks at English.
				swalert
					title: "D:"
					text: "Er is iets fout gegaan tijdens het opslaan van je instellingen.\nWe zijn op de hoogte gesteld."
					type: "error"
			else if not success?
				shake "#accountInfoModal"

			$("#accountInfoModal").modal "hide"
			undefined

		any = no # If this is false we will just close the modal later.
		if mail isnt Meteor.user().emails[0].address
			any = yes
			Meteor.call "changeMail", mail, (e) -> callback not e?

		if profile.firstName isnt firstName or profile.lastName isnt lastName
			any = yes
			Meteor.users.update Meteor.userId(), {
				$set:
					"profile.firstName": firstName
					"profile.lastName": lastName
			}, (e) -> callback not e?

		if oldPass isnt "" and newPass isnt ""
			any = yes

			if oldPass isnt newPass
				Accounts.changePassword oldPass, newPass, (error) ->
					if error?
						if error.reason is "Incorrect password"
							setFieldError "#oldPassInput", "Verkeerd wachtwoord"
							callback null
						else callback no

					else
						$("#accountInfoModal").modal "hide"
						callback yes

			else
				setFieldError "#newPassInput", "Het nieuwe wachtwoord is hetzelfde als je oude wachtwoord."
				callback null

		unless any then callback null

Template.addProjectModal.helpers
	assignments: ->
		MagisterAssignments.find({
			_deadline: $gte: new Date
		}, {
			sort:
				"_deadline": 1
				"_abbreviation": 1
		}).map (a) -> _.extend a,
			project: Projects.findOne magisterId: a.id()
			__class: Classes.findOne _.find(Meteor.user().classInfos, (z) -> z.magisterId is a.class()._id).id

Template.addProjectModal.events
	"click #createButton": ->
		@added = yes
		project = new Project @name(), @description(), @deadline(), Meteor.userId(), @__class._id, @id()
		Projects.insert project, (e) => @added = not e?
		$("#addProjectModal").modal "hide"

	"click .goToProjectButton": (event) ->
		Router.go "projectView", projectId: $(event.target).attr "id"
		$("#addProjectModal").modal "hide"

	"click #goButton": ->
		name = $("#projectNameInput").val().trim()
		description = $("#projectDescriptionInput").val().trim()
		deadline = $("#projectDeadlineInput").data("DateTimePicker").date().toDate()
		classId = Session.get("currentSelectedClassDatum")?._id

		return if name is ""
		if Projects.findOne({ name })?
			setFieldError "#projectNameInput", "Er is al een project met deze naam"
			return

		if $("#projectClassNameInput").val().trim() isnt "" and not classId?
			shake "#addProjectModal"
			return

		project = new Project name, description, deadline, Meteor.userId(), classId, null
		Projects.insert project

		$("#addProjectModal").modal "hide"

Template.addProjectModal.rendered = ->
	ownClassesEngine = new Bloodhound
		name: "ownClasses"
		datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.name
		queryTokenizer: Bloodhound.tokenizers.whitespace
		local: []

	ownClassesEngine.initialize()

	@autorun (c) ->
		ownClassesEngine.clear()
		ownClassesEngine.add classes().fetch()

	$("#projectClassNameInput").typeahead(null,
		source: ownClassesEngine.ttAdapter()
		displayKey: "name"
	).on "typeahead:selected", (obj, datum) -> Session.set "currentSelectedClassDatum", datum

	$("#projectDeadlineInput").datetimepicker
		locale: moment.locale()
		defaultDate: new Date()
		icons:
			time: "fa fa-clock-o"
			date: "fa fa-calendar"
			up: "fa fa-arrow-up"
			down: "fa fa-arrow-down"
			previous: "fa fa-chevron-left"
			next: "fa fa-chevron-right"

# == End Modals ==

# == Sidebar ==

Template.sidebar.helpers
	"classes": -> classes()

Template.sidebar.events
	"click .bigSidebarButton": (event) -> slide $(event.target).attr "id"

	"click .sidebarFooterSettingsIcon": -> App.showModal 'settingsModal'
	"click #addClassButton": ->
		# Reset AddClassModal inputs
		$('#classNameInput').val ''
		$('#courseInput').val ''
		$('#bookInput').val ''
		$('#colorInput').colorpicker 'setValue', '#333'

		App.showModal 'addClassModal'

		addClassComp = Tracker.autorun ->
			Meteor.subscribe "scholieren.com"

			classEngine.clear()
			classEngine.add ScholierenClasses.find().fetch()

# == End Sidebar ==

setMobileSettings = ->
	snapper = new Snap
		element: document.getElementById 'wrapper'
		minPosition: -200
		maxPosition: 200
		flickThreshold: 45
		resistance: .9
	window.closeSidebar = -> snapper.close()

	$('body').addClass 'chatSidebarOpen'

setKeyboardShortcuts = ->
	Mousetrap.bind ['a', 'c'], ->
		Router.go 'calendar'
		return no

	Mousetrap.bind 'o', ->
		Router.go 'app'
		return no

	Mousetrap.bind ['/', '?'], ->
		$('div.searchBox > input').focus()
		return no

	buttonGoto = (delta) ->
		buttons = $('.sidebarButton').get()
		oldIndex = buttons.indexOf $('.sidebarButton.selected').get()[0]
		index = (oldIndex + delta) % buttons.length

		id = buttons[if index is -1 then buttons.length - 1 else index].id
		switch id
			when 'overview' then Router.go 'app'
			when 'calendar' then Router.go 'calendar'
			else Router.go 'classView', classId: id

	Mousetrap.bind ['shift+up', 'shift+k'], ->
		buttonGoto -1
		return no

	Mousetrap.bind ['shift+down', 'shift+j'], ->
		buttonGoto 1
		return no

	Mousetrap.bind ['ctrl+/', 'command+/', 'ctrl+?', 'command+?'], ->
		alertModal 'Toetsenbord shortcuts', Locals['nl-NL'].KeyboardShortcuts(), DialogButtons.Ok, { main: 'Sluiten' }, { main: 'btn-primary' }
		return no

Template.app.helpers
	pageColor: -> Session.get("pageColor") ? "lightgray"
	pageTitle: -> Session.get("headerPageTitle") ? ""

	currentBigNotice: -> currentBigNotice.get()

Template.app.events
	'click .headerIcon': (event) ->
		if window.snapper.state().state is 'closed'
			window.snapper.open event.target.dataset.snapSide
		else
			window.snapper.close()

	'click #bigNotice > #content': -> currentBigNotice.get().onClick? arguments...
	'click #bigNotice > #dismissButton': -> currentBigNotice.get().onDismissed? arguments...

Template.app.rendered = ->
	# REFACTOR THE SHIT OUT OF THIS.

	if Meteor.userId()? and not Meteor.user().emails[0].verified and
	not Session.get('showedMailVerificationWarning') and
	Helpers.daysRange(Meteor.user().creationDate, new Date(), no) >= 2
		notify 'Je hebt je account nog niet geverifiëerd.\nCheck je email!', 'warning'
		Session.set 'showedMailVerificationWarning', yes

	val = Meteor.user().profile.birthDate
	now = new Date()
	if not amplify.store('congratulated') and val? and Helpers.datesEqual now, val
		swalert
			title: 'Gefeliciteerd!'
			text: "Gefeliciteerd met je #{moment().diff val, 'years'}e verjaardag!"
		amplify.store 'congratulated', yes, expires: 172800000 # 2 days, just to make sure.

	Deps.autorun ->
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

	if Session.get('isPhone') then setMobileSettings()
	else
		setKeyboardShortcuts()

		# `startMonitor` will throw an error when the time isn't synced yet, when
		# the time is done syncing the current computation will invalidate, so to
		# effectively enable the monitor ASAP we put it inside of an `autorun` and a
		# `try`.
		Deps.autorun -> try UserStatus.startMonitor idleOnBlur: yes

	if not amplify.store('allowCookies') and $('.cookiesContainer').length is 0
		Blaze.render Template.cookies, document.body
		$cookiesContainer = $ '.cookiesContainer'

		$cookiesContainer
			.css visibility: 'initial'
			.velocity { bottom: 0 }, 1200, 'easeOutExpo'

		$cookiesContainer.find('#acceptCookiesButton').click ->
			amplify.store 'allowCookies', yes
			$cookiesContainer.velocity { bottom: '-500px' }, 2400, 'easeOutExpo', -> $(this).remove()
