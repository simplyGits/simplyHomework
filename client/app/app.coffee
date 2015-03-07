schoolSub = null
magisterClassesComp = null
addClassComp = null
@snapper = null
magisterClasses = new ReactiveVar null

class @App
	@_setupPathItems:
		welcome:
			done: yes
			func: ->
				alertModal "Hey!", Locals["nl-NL"].GreetingMessage(), DialogButtons.Ok, { main: "verder" }, { main: "btn-primary" }, {main: ->
					App.step()
				}, no
		magisterInfo:
			done: no
			func: ->
				schoolSub = Meteor.subscribe "schools", -> $("#setMagisterInfoModal").modal backdrop: "static", keyboard: no
		plannerPrefs:
			done: no
			func: ->
				$("#plannerPrefsModal").modal backdrop: "static", keyboard: no
				$("#plannerPrefsModal .modal-header button").remove()
		getMagisterClasses:
			done: no
			func: ->
				magisterClassesComp = Tracker.autorun -> # Subscribes should be stopped when this computation is stopped later.
					Meteor.subscribe "scholieren.com"
					year = schoolVariant = null
					Tracker.nonreactive -> { year, schoolVariant } = Meteor.user().profile.courseInfo

					classes = magisterResult("classes").result ? []
					c.__scholierenClass = ScholierenClasses.findOne(-> c.description().toLowerCase().indexOf(@name.toLowerCase()) > -1) for c in classes
					magisterClasses.set classes

					for c in classes
						scholierenClass = c.__scholierenClass
						classId = Classes.findOne(name: scholierenClass?.name ? Helpers.cap(c.description()), schoolVariant: schoolVariant, year: year)?._id

						Meteor.subscribe("books", classId) if classId?

						books = scholierenClass?.books ? []
						books.pushMore Books.find({ classId }).fetch()

						engine = new Bloodhound
							name: "books"
							datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.title
							queryTokenizer: Bloodhound.tokenizers.whitespace
							local: _.uniq books, "title"

						engine.initialize()

						Meteor.defer do (engine, c) -> return ->
							$("#magisterClassesResult > div##{c.id()} > input")
								.typeahead null,
									source: engine.ttAdapter()
									displayKey: "title"
								.on "typeahead:selected", (obj, datum) -> c.__method = datum

					Meteor.defer ->
						for x in $("#magisterClassesResult > div").colorpicker(input: null)
							$(x)
								.on "changeColor", (e) -> $(@).attr "colorHex", e.color.toHex()
								.colorpicker "setValue", "##{("00000" + (Math.random() * (1 << 24) | 0).toString(16)).slice -6}"

					$("#getMagisterClassesModal").modal backdrop: "static", keyboard: no

		newSchoolYear:
			done: no
			func: ->
				alertModal "Hey!", Locals["nl-NL"].NewSchoolYear(), DialogButtons.Ok, { main: "verder" }, { main: "btn-primary" }, { main: -> return }, no
		final:
			done: yes
			func: ->
				swalert
					type: "success"
					title: "Klaar!"
					text: "Wil je een complete rondleiding volgen?"
					confirmButtonText: "Rondleiding"
					cancelButtonText: "Afsluiten"
					onSuccess: -> App.runTour()

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

	@_fullCount: 0
	@_running: no

	###*
	# Moves the setup path one item further.
	#
	# @method step
	# @return {Object} Object that gives information about the progress of the setup path.
	###
	@step = ->
		return if @_fullCount is 0

		item = _.find @_setupPathItems, (i) -> not i.done
		unless item?
			@_fullCount = 0
			@_running = no
			return

		item.func()
		item.done = yes

	###*
	# Initializes and starts the setup path.
	#
	# @method followSetupPath
	###
	@followSetupPath: ->
		return if @_running
		@_setupPathItems.plannerPrefs.done = @_setupPathItems.magisterInfo.done = Meteor.user().magisterCredentials?
		@_setupPathItems.getMagisterClasses.done = Meteor.user().classInfos? and Meteor.user().classInfos.length > 0
		@_setupPathItems.newSchoolYear.done = yes

		@_fullCount = _.filter(@_setupPathItems, (x) -> not x.done).length
		@_setupPathItems.welcome.done = @_setupPathItems.final.done = @_fullCount is 0
		@_running = yes

		@step()

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

Template.getMagisterClassesModal.helpers
	magisterClasses: -> magisterClasses.get()

Template.getMagisterClassesModal.rendered = ->
	magisterResult "course", (e, r) ->
		return if e? or amplify.store "courseInfoSet_#{Meteor.userId()}"

		schoolVariant = /[^\d\s]+/.exec(r.type().description)[0].trim().toLowerCase()
		year = (Number) /\d+/.exec(r.type().description)[0].trim()

		Meteor.users.update Meteor.userId(), $set:
			"profile.courseInfo": {
				profile: r.profile()
				alternativeProfile: r.alternativeProfile()
				schoolVariant
				year
			}

		amplify.store "courseInfoSet_#{Meteor.userId()}", yes, expires: 172800000 # We don't want to be spammed under, thank you.

	opts =
		lines: 17
		length: 7
		width: 2
		radius: 18
		corners: 0
		rotate: 0
		direction: 1
		color: "#000"
		speed: .9
		trail: 10
		shadow: no
		hwaccel: yes
		className: "spinner"
		top: "65%"
		left: "50%"

	spinner = new Spinner(opts).spin $("#spinner").get()[0]

Template.getMagisterClassesModal.events
	"click .fa-times": (event) -> magisterClasses.set _.reject magisterClasses.get(), @
	"keyup #method": (event) ->
		unless event.target.value is @__method?.title and not _.isEmpty event.target.value
			@__method =
				title: Helpers.cap event.target.value
				id: null

	"click #goButton": ->
		{ year, schoolVariant } = Meteor.user().profile.courseInfo

		Meteor.users.update(Meteor.userId(), $set: classInfos: []) unless Meteor.user().classInfos?

		for c in magisterClasses.get()
			color = $("#magisterClassesResult > div##{c.id()}").attr "colorHex"
			_class = Classes.findOne
				$or: [
					{ $where: -> c.description().toLowerCase().indexOf(@name.toLowerCase()) > -1}
					{ course: c.abbreviation().toLowerCase() }
				]
				schoolVariant: schoolVariant
				year: year

			_class ?= New.class c.description(), c.abbreviation(), year, schoolVariant, c.__scholierenClass?.id

			if (val = c.__method)?
				book = Books.findOne title: val.title
				unless book? or val.title.trim() is ""
					book = New.book val.title, undefined, val.id, undefined, _class._id

			Meteor.users.update Meteor.userId(), $push: classInfos:
				id: _class._id
				color: color
				magisterId: c.id()
				magisterDescription: c.description()
				magisterAbbreviation: c.abbreviation()
				bookId: book?._id ? null

		$("#getMagisterClassesModal").modal "hide"
		magisterClassesComp.stop()
		App.step()

Template.setMagisterInfoModal.events
	"click #goButton": ->
		schoolName = Helpers.cap $("#schoolNameInput").val()
		s = Session.get("currentSelectedSchoolDatum")
		MagisterSchool.getSchools schoolName, (e, r) ->
			s ?= ( r ? [] )[0]
			username = $("#magisterUsernameInput").val().trim()
			password = $("#magisterPasswordInput").val()

			school = Schools.findOne { name: schoolName }
			school ?= New.school schoolName, s.url, new Location()

			unless $("#allowGroup input").is ":checked"
				shake "#setMagisterInfoModal"
				return

			Meteor.call "setMagisterInfo", { school, schoolId: school._id, magisterCredentials: { username, password }}, (e, success) ->
				if not e? and success
					$("#setMagisterInfoModal").modal "hide"
					App.step()
					initializeMagister yes
					schoolSub.stop()
				else shake "#setMagisterInfoModal"

Template.setMagisterInfoModal.rendered = ->
	$("#schoolNameInput").typeahead({
		minLength: 3
	}, {
		displayKey: "name"
		source: (query, callback) ->
			MagisterSchool.getSchools query, (e, r) -> callback r unless e?
	}).on "typeahead:selected", (obj, datum) -> Session.set "currentSelectedSchoolDatum", datum

dayWeek = [{ friendlyName: "Maandag", name: "monday" }
	{ friendlyName: "Dinsdag", name: "tuesday" }
	{ friendlyName: "Woensdag", name: "wednesday" }
	{ friendlyName: "Donderdag", name: "thursday" }
	{ friendlyName: "Vrijdag", name: "friday" }
	{ friendlyName: "Zaterdag", name: "saturday" }
	{ friendlyName: "Zondag", name: "sunday" }
]

Template.plannerPrefsModal.helpers
	dayWeek: -> dayWeek
	weigthOptions: -> return [ { name: "Geen" }
		{ name: "Weinig" }
		{ name: "Gemiddeld", selected: true }
		{ name: "Veel" }
	]

Template.plannerPrefsModal.rendered = ->
	# Set the data on the modal, if available
	return unless Get.schedular()?

	dayWeeks = _.sortBy _.filter(Get.schedular().schedularPrefs().dates(), (dI) -> !dI.date()? and _.isNumber dI.weekday()), (dI) -> dI.weekday()
	return if dayWeeks.length isnt 7

	for i in [0...dayWeek.length]
		day = dayWeeks[i]
		value = switch day.availableTime()
			when 0 then "Geen"
			when 1 then "Weinig"
			when 2 then "Gemiddeld"
			when 3 then "Veel"
		$("##{dayWeek[i].name}Input").val value

Template.plannerPrefsModal.events
	"click #goButton": =>
		schedular = Get.schedular() ? New.schedular()
		schedularPrefs = new SchedularPrefs
		for day in dayWeek
			schedularPrefs.dates().push new DateInfo @DayEnum[Helpers.cap day.name], switch $("##{day.name}Input").val()
				when "Geen" then 0
				when "Weinig" then 1
				when "Gemiddeld" then 2
				when "Veel" then 3
		schedular.schedularPrefs schedularPrefs
		Meteor.users.update Meteor.userId(), $set: { schedular }

		$("#plannerPrefsModal").modal "hide"

		App.step()

Template.addClassModal.events
	"click #goButton": (event) ->
		name = Helpers.cap $("#classNameInput").val()
		course = $("#courseInput").val().toLowerCase()
		bookName = $("#bookInput").val()
		color = $("#colorInput").val()
		{ year, schoolVariant } = Meteor.user().profile.courseInfo

		_class = Classes.findOne { $or: [{ name: name }, { course: course }], schoolVariant: schoolVariant, year: year}
		_class ?= New.class name, course, year, schoolVariant, ScholierenClasses.findOne(-> @name.toLowerCase().indexOf(val.toLowerCase()) > -1).id

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

Template.settingsModal.events
	"click #schedularPrefsButton": ->
		$("#settingsModal").modal "hide"
		$("#plannerPrefsModal").modal()
	"click #accountInfoButton": ->
		$("#settingsModal").modal "hide"
		$("#accountInfoModal").modal()
	"click #clearInfoButton": ->
		$("#settingsModal").modal "hide"
		alertModal "Hey!", Locals["nl-NL"].ClearInfoWarning(), DialogButtons.OkCancel, { main: "zeker weten" }, { main: "btn-danger" }, main: ->
			Meteor.users.update Meteor.userId(), $set:
				classInfos: null
				"profile.schoolId": null
				"profile.magisterPicture": null
				"profile.groupInfos": null
			Meteor.call "clearMagisterInfo"
			document.location.reload()

	"click #startTourButton": ->
		$("#settingsModal").modal "hide"
		App.runTour()

	"click #logOutButton": ->
		Router.go "launchPage"
		Meteor.logout()

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
		oldPass = $("#oldPassInput").val()
		newPass = $("#newPassInput").val()
		newMail = mail isnt Meteor.user().emails[0].address
		hasNewPass = oldPass isnt "" and newPass isnt ""

		if newMail
			Meteor.call "changeMail", mail
			$("#accountInfoModal").modal "hide"
			unless hasNewPass then swalert title: "Mailadres aangepast", type: "success", text: "Je krijgt een mailtje op je nieuwe email adress voor verificatie"

		if hasNewPass and oldPass isnt newPass
			Accounts.changePassword oldPass, newPass, (error) ->
				if error?.reason is "Incorrect password"
					$("#oldPassInput").addClass("has-error").tooltip(placement: "bottom", title: "Verkeerd wachtwoord").tooltip("show")
				else
					$("#accountInfoModal").modal "hide"
					swalert title: ":D", type: "success", text: "Wachtwoord aangepast! Voortaan kan je met je nieuwe wachtwoord inloggen." + (if newMail then "Je krijgt een mailtje op je nieuwe email adress voor verificatie" else "")
		else if oldPass is newPass
			$("#newPassInput").addClass("has-error").tooltip(placement: "bottom", title: "Nieuw wachtwoord is hetzelfde als je oude wachtwoord.").tooltip("show")

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
		project = new Project @name(), @description(), @deadline(), @id(), @__class._id, Meteor.userId()
		Projects.insert project, (e) => @added = not e?
		$("#addProjectModal").modal "hide"

	"click .goToProjectButton": (event) ->
		Router.go "projectView", projectId: $(event.target).attr "id"
		$("#addProjectModal").modal "hide"

	"click #goButton": ->
		name = $("#projectNameInput").val().trim()
		description = $("#projectDescriptionInput").val().trim()
		deadline = $("#projectDeadlineInput").data("DateTimePicker").getDate().toDate()
		classId = Session.get("currentSelectedClassDatum")?._id

		return if name is ""

		if $("#projectClassNameInput").val().trim() isnt "" and not classId?
			shake "#addProjectModal"
			return

		New.project name, description, deadline, null, classId, Meteor.userId()

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

	$("#projectDeadlineInput").datetimepicker language: "nl", defaultDate: new Date()

# == End Modals ==

# == Sidebar ==

Template.sidebar.helpers
	"classes": -> classes()

Template.sidebar.events
	"click .bigSidebarButton": (event) -> slide $(event.target).attr "id"

	"click .sidebarFooterSettingsIcon": -> $("#settingsModal").modal()
	"click #addClassButton": ->
		# Reset AddClassModal inputs
		$("#classNameInput").val("")
		$("#courseInput").val("")
		$("#bookInput").val("")
		$("#colorInput").colorpicker 'setValue', "#333"

		$("#addClassModal").modal()

		addClassComp = Tracker.autorun ->
			Meteor.subscribe "scholieren.com"

			classEngine.clear()
			classEngine.add ScholierenClasses.find().fetch()

# == End Sidebar ==

Template.app.helpers
	contentOffsetLeft: -> if Session.get "isPhone" then "0" else "200px"
	contentOffsetRight: -> if Session.get "isPhone" then "0" else "50px"

Template.app.rendered = ->
	if "#{Math.random()}"[2] is "2" and "#{Math.random()}"[4] is "2"
		console.error "CRITICAL ERROR: UNEXPECTED KAAS"

	Deps.autorun ->
		if Meteor.user()?.magisterCredentials?
			initializeMagister()

	Deps.autorun (c) ->
		if Meteor.user()? and Meteor.status().connected and not Meteor.user().hasGravatar
			$.get("#{Meteor.user().gravatarUrl}&s=1&d=404").done ->
				Meteor.users.update Meteor.userId(), $set: hasGravatar: yes

	if Meteor.user()? and not Meteor.user().emails[0].verified
		notify "Je hebt je account nog niet geverifiëerd!", "warning"

	assignmentNotification = null
	recentGradesNotification = null

	@autorun ->
		return unless Meteor.subscribe("magisterAssignments").ready()
		assignments = MagisterAssignments.find({
			_deadline:
				$gte: new Date
				$lte: Date.today().addDays 7
			_finished: no
		}, {
			sort: "_deadline": 1
		}).fetch()

		projects = Projects.find({
			deadline:
				$gte: new Date
				$lte: Date.today().addDays 7
		}, {
			transform: projectTransform
			sort: "deadline": 1
		}).fetch()

		return if assignments.length is 0 and projects.length is 0

		s = "Projecten en opdrachten met deadline binnenkort:\nKlik voor meer info.\n\n"
		for assignment in assignments when not _.find(projects, (p) -> p.magisterId is assignment.id())?
			d = if (d = assignment.deadline()).getHours() is 0 and d.getMinutes() is 0 then d.addDays(-1) else d
			s += "<b>#{assignment.class()._abbreviation}</b> #{assignment.name()} - #{DayToDutch(Helpers.weekDay(d))}\n"

		for project in projects
			d = if (d = project.deadline).getHours() is 0 and d.getMinutes() is 0 then d.addDays(-1) else d
			if project.__class?
				s += "<b>#{project.__class.course}</b> #{project.name} - #{DayToDutch(Helpers.weekDay(d))}\n"
			else
				s += "#{project.name} - #{DayToDutch(Helpers.weekDay(d))}\n"

		if assignmentNotification?
			assignmentNotification.content s, yes
		else
			assignmentNotification = NotificationsManager.notify body: s, type: "warning", time: -1, html: yes, onClick: -> $("#addProjectModal").modal()

	recentGrades = new ReactiveVar []
	magisterResult "recent grades", (e, r) ->
		return if e? or r.length is 0
		recentGrades.set r

	@autorun ->
		r = recentGrades.get()
		gradeNotificationDismissTime = Meteor.user().gradeNotificationDismissTime

		recentGradesFiltered = _.reject r, (g) -> gradeNotificationDismissTime > new Date(g.dateFilledIn())
		unless recentGradesFiltered.length is 0
			s = "Recent ontvangen cijfers:\n\n"

			for c in (z.class() for z in _.uniq recentGradesFiltered, "_class")
				grades = _.filter recentGradesFiltered, (g) -> g.class() is c
				s += "<b>#{c.abbreviation()}</b> - #{grades.map((z) -> if Number(z.grade().replace(",", ".")) < 5.5 then "<b style=\"color: red\">#{z.grade()}</b>" else z.grade()).join ' & '}\n"

			if recentGradesNotification?
				recentGradesNotification.content s, yes
			else
				recentGradesNotification = NotificationsManager.notify body: s, type: "warning", time: -1, html: yes, onHide: -> Meteor.users.update(Meteor.userId(), $set: gradeNotificationDismissTime: new Date)

	@autorun ->
		appointments = magisterAppointment new Date(), new Date().addDays(7)
		Tracker.nonreactive ->
			tmpGroupInfos = Meteor.user().profile.groupInfos ? []

			for classInfo in (Meteor.user().classInfos ? [])
				magisterGroup = _.find(appointments, (a) -> a.classes()[0] is classInfo.magisterDescription)?.description()
				groupInfo = _.find tmpGroupInfos, (gi) -> gi.id is classInfo.id

				continue if groupInfo?.group is magisterGroup or not magisterGroup?

				_.remove tmpGroupInfos, id: classInfo.id
				tmpGroupInfos.push _.extend id: classInfo.id, group: magisterGroup

			Meteor.users.update Meteor.userId(), $set: "profile.groupInfos": tmpGroupInfos

	# Pilot quick and dirty goaledSchedule creating.
	@autorun ->
		appointments = magisterAppointment new Date, new Date().addDays 7
		tests = _.filter appointments, (a) -> _.contains ["test", "quiz"], a.infoTypeString()

		for a in tests
			if GoaledSchedules.find(magisterAppoinmentId: a.id()).count() is 0
				gs = new GoaledSchedule Meteor.userId(), Parser.parseDescription(a.content(), a.infoTypeString()), a.begin().date(), a.__class
				gs.magisterAppoinmentId = a.id()
				GoaledSchedules.insert gs

	studyGuideChangeNotification = null
	@autorun (c) ->
		return unless Meteor.subscribe("magisterStudyGuides").ready() # Wait till the subscription is ready.
		Meteor.setInterval (-> c.invalidate()), 1200000 # Make sure to rerun this computation after 20 minutes.

		studyGuides = MagisterStudyGuides.find().fetch()
		studyGuidesHashes = {}
		oldStudyGuideHashes = Meteor.user().studyGuidesHashes

		for studyGuide in studyGuides then do (studyGuide) ->
			parts = _.sortBy ( { id: x.id(), description: x.description(), fileSizes: (z.size() for z in x.files()) } for x in studyGuide.parts ), "id"
			studyGuidesHashes[studyGuide.id()] = md5(EJSON.stringify parts).substring 0, 6

		if EJSON.equals studyGuidesHashes, oldStudyGuideHashes
			studyGuideChangeNotification?.hide()
			return

		if _.isEmpty(oldStudyGuideHashes)
			Meteor.users.update Meteor.userId(), $set: { studyGuidesHashes }
			return

		s = "Studiewijzers die veranderd zijn:\n\n"
		x = _(studyGuidesHashes)
			.keys()
			.filter((s) -> studyGuidesHashes[s] isnt oldStudyGuideHashes[s])
			.map((id) -> _.find(studyGuides, (sg) -> sg.id() is +id))
			.sortBy((sg) -> sg.classCodes()[0])
			.value()

		s += "<b>#{studyGuide.classCodes()[0]}</b> - #{studyGuide.name()}\n" for studyGuide in x

		if studyGuideChangeNotification?
			studyGuideChangeNotification.content s, yes
		else
			studyGuideChangeNotification = NotificationsManager.notify
				body: s
				type: "warning"
				time: -1
				html: yes
				onHide: -> Meteor.users.update Meteor.userId(), $set: { studyGuidesHashes }
				onClick: ->
					return unless _.uniq(x, "_class").length is 1
					Router.go "classView", classId: _.find(Meteor.user().classInfos, (z) -> z.magisterId is x[0].class()._id).id.toHexString()

	val = Meteor.user().profile.birthDate
	now = new Date()
	if val?.getMonth() is now.getMonth() and val?.getDate() is now.getDate() and not amplify.store("congratulated")?
		swalert title: "Gefeliciteerd!", text: "Gefeliciteerd met je #{moment().diff(val, "years")}e verjaardag!"
		amplify.store "congratulated", yes, expires: 172800000

	Deps.autorun ->
		return
		if Meteor.user()? and not has("noAds") and Meteor.status().connected
			setTimeout (-> Meteor.defer ->
				if !Session.get "adsAllowed"
					Router.go "launchPage"
					Meteor.logout()
					swalert title: "Adblock :c", html: 'Om simplyHomework gratis beschikbaar te kunnen houden zijn we afhankelijk van reclame-inkomsten.\nOm simplyHomework te kunnen gebruiken, moet je daarom je AdBlocker uitzetten.\nWil je toch simplyHomework zonder reclame gebruiken, dan kan je <a href="/">premium</a> nemen.', type: "error"
			), 3000

	if Session.get("isPhone") then setMobile()
	else setShortcuts()

	if !amplify.store("allowCookies") and $(".cookiesContainer").length is 0
		Blaze.render Template.cookies, $("body").get()[0]
		$(".cookiesContainer")
			.css visibility: "initial"
			.velocity { bottom: 0 }, 1200, "easeOutExpo"

		$("#acceptCookiesButton").click ->
			amplify.store "allowCookies", yes
			$(".cookiesContainer").velocity { bottom: "-500px" }, 2400, "easeOutExpo", -> $(@).remove()

setMobile = ->
	snapper = new Snap
		element: $(".content")[0]
		minPosition: -200
		maxPosition: 200
		flickThreshold: 45
		resistance: .9

	$("body").addClass "chatSidebarOpen"

	@closeSidebar = -> snapper.close()

setShortcuts = ->
	Mousetrap.bind ["a", "c"], ->
		Router.go "calendar"
		return no

	Mousetrap.bind "o", ->
		Router.go "app"
		return no

	Mousetrap.bind ["/", "?"], ->
		$("div.searchBox > input").focus()
		return no

	buttonGoto = (delta) ->
		buttons = $(".sidebarButton").get()
		oldIndex = buttons.indexOf $(".sidebarButton.selected").get()[0]
		index = (oldIndex + delta) % buttons.length

		id = buttons[if index is -1 then buttons.length - 1 else index].id
		switch id
			when "overview" then Router.go "app"
			when "calendar" then Router.go "calendar"
			else Router.go "classView", classId: id

	Mousetrap.bind ["shift+up", "shift+k"], ->
		buttonGoto -1
		return no

	Mousetrap.bind ["shift+down", "shift+j"], ->
		buttonGoto 1
		return no

	Mousetrap.bind ["ctrl+/", "command+/", "ctrl+?", "command+?"], ->
		alertModal "Toetsenbord shortcuts", Locals["nl-NL"].KeyboardShortcuts(), DialogButtons.Ok, { main: "Sluiten" }, { main: "btn-primary" }
		return no
