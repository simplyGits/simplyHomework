@snapper = null
class @App
	@firstTimeSetup: ->
		alertModal "Hey!", Locals["nl-NL"].GreetingMessage(), DialogButtons.Ok, { main: "verder" }, { main: "btn-primary" }, main: ->
			$("#setMagisterInfoModal").modal()

	@newSchoolYear: ->
		alertModal "Hey!", Locals["nl-NL"].NewSchoolYear(), DialogButtons.Ok, { main: "verder" }, { main: "btn-primary" }, main: -> return

# == Bloodhounds ==

@bookEngine = new Bloodhound
	name: "books"
	datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.val
	queryTokenizer: Bloodhound.tokenizers.whitespace
	local: []

classEngine = new Bloodhound
	name: "classes"
	datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.val
	queryTokenizer: Bloodhound.tokenizers.whitespace
	local: []

# == End Bloodhounds ==

# == Modals ==

Template.setMagisterInfoModal.events
	"click #goButton": ->
		schoolName = Helpers.cap $("#schoolNameInput").val()
		schoolUrl = Session.get("currentSelectedSchoolDatum")?.Url[5..]
		schoolUrl ?= ""
		username = $("#magisterUsernameInput").val()
		password = $("#magisterPasswordInput").val()

		school = Schools.findOne { _name: schoolName }
		school ?= New.school schoolName, schoolUrl, new Location()

		Meteor.call "setMagisterInfo", { url: schoolUrl, schoolId: school._id, magisterCredentials: { username, password }}, (error, result) ->
			if result
				$("#setMagisterInfoModal").modal "hide"
				$("#plannerPrefsModal").modal()
			else
				$("#setMagisterInfoModal").addClass "animated shake"
				$('#setMagisterInfoModal').one 'webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', ->
					$("#setMagisterInfoModal").removeClass "animated shake"

Template.setMagisterInfoModal.rendered = ->
	$("#schoolNameInput").typeahead({
		minLength: 3
	}, {
		displayKey: "Licentie"
		source: (query, callback) ->
			Meteor.call "http", "GET", "https://schoolkiezer.magister.net/home/query?filter=#{query}", (error, result) -> unless error? then callback EJSON.parse result.content
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
		schedular = Get.schedular() ? New.schedular Meteor.userId()
		schedularPrefs = new SchedularPrefs schedular
		for day in dayWeek
			schedularPrefs.addDateInfo @DayEnum[Helpers.cap day.name], switch $("##{day.name}Input").val()
				when "Geen" then 0
				when "Weinig" then 1
				when "Gemiddeld" then 2
				when "Veel" then 3
		schedular.schedularPrefs schedularPrefs

		$("#plannerPrefsModal").modal "hide"

Template.addClassModal.events
	"click #goButton": (event) ->
		name = Helpers.cap $("#classNameInput").val()
		course = $("#courseInput").val().toLowerCase()
		bookName = $("#bookInput").val()
		year = (Number) $("#yearInput").val()
		schoolVariant = $("#schoolVariantInput").val().toLowerCase()
		color = $("#colorInput").val()

		_class = Classes.findOne { $or: [{ _name: name }, { _course: course }], _schoolVariant: schoolVariant, _year: year}
		_class ?= New.class name, course, year, schoolVariant

		book = _class.books().smartFind bookName, (b) -> b.title()
		book ?= _class.addBook bookName, undefined, Session.get("currentSelectedBookDatum")?.id, undefined

		Meteor.users.update Meteor.userId(), { $push: { classInfos: { id: _class._id, color, bookId: book._id }}}
		$("#addClassModal").modal "hide"

	"keydown #classNameInput": ->
		val = Helpers.cap $("#classNameInput").val()

		if /(Natuurkunde)|(Scheikunde)/ig.test val
			val = "Natuur- en scheikunde"
		else if /(Wiskunde( (a|b|c|d))?)|(Rekenen)/ig.test val
			val = "Wiskunde / Rekenen"
		else if /levensbeschouwing/ig.test val
			val = "Godsdienst en levensbeschouwing"

		WoordjesLeren.getAllBooks val, (result) ->
			bookEngine.clear()
			bookEngine.add ( { id: s.id, val: s.name } for s in result )

Template.addClassModal.rendered = ->
	$("#colorInput").colorpicker color: "#333"
	$("#colorInput").on "changeColor", -> $("#colorLabel").css color: $("#colorInput").val()

	WoordjesLeren.getAllClasses (result) ->
		#classes = Classes.find(_name: $nin: (Helpers.cap c for c in result.pushMore(extraClassList) )).map((c) -> c._name).pushMore(extraClassList).pushMore(result)
		classEngine.add ( { val: s } for s in result.pushMore(extraClassList) when !_.contains ["Overige talen",
			"Overige vakken",
			"Eigen methodes",
			"Wiskunde / Rekenen",
			"Natuur- en scheikunde",
			"Godsdienst en levensbeschouwing"], s )

	bookEngine.initialize()
	classEngine.initialize()

	$("#bookInput").typeahead(null,
		source: bookEngine.ttAdapter()
		displayKey: "val"
	).on "typeahead:selected", (obj, datum) -> Session.set "currentSelectedBookDatum", datum

	$("#classNameInput").typeahead null,
		source: classEngine.ttAdapter()
		displayKey: "val"

Template.settingsModal.events
	"click #schedularPrefsButton": ->
		$("#settingsModal").modal "hide"
		$("#plannerPrefsModal").modal()
	"click #accountInfoButton": ->
		$("#settingsModal").modal "hide"
		$("#accountInfoModal").modal()
	"click #logOutButton": ->
		Router.go "app"
		Meteor.logout()

Template.newSchoolYearModal.classes = -> classes()

Template.newSchoolYearModal.events
	"change": (event) ->
		target = $(event.target)
		checked = target.is ":checked"
		classId = target.attr "classid"

		target.find("span").css color: if checked then "lightred" else "white"

Template.accountInfoModal.currentMail = -> Meteor.user().emails[0].address

Template.accountInfoModal.events
	"click #goButton": ->
		mail = $("#mailInput").val().toLowerCase()
		oldPass = $("#oldPassInput").val()
		newPass = $("#newPassInput").val()
		newMail = mail isnt Meteor.user().emails[0].address
		hasNewPass = oldPass isnt "" and newPass isnt ""

		if newMail
			Meteor.users.update Meteor.userId(), $set: { "emails": [ { address: mail, verified: no } ] }
			Meteor.call "verifyMail"
			$("#accountInfoModal").modal "hide"
			unless hasNewPass then alertModal ":D", "Je krijgt een mailtje op je nieuwe email adress voor verificatie"

		if hasNewPass and oldPass isnt newPass
			Accounts.changePassword oldPass, newPass, (error) ->
				if error?.reason is "Incorrect password"
					$("#oldPassInput").addClass("has-error").tooltip(placement: "bottom", title: "Verkeerd wachtwoord").tooltip("show")
				else
					$("#accountInfoModal").modal "hide"
					alertModal ":D", "Wachtwoord aangepast! Voortaan kan je met je nieuwe wachtwoord inloggen." + (if newMail then "Je krijgt een mailtje op je nieuwe email adress voor verificatie" else "")


# == End Modals ==

# == Sidebar ==

Template.sidebar.helpers
	"classes": -> classes()
	"sidebarOverflow": -> if Session.get "sidebarOpen" then "auto" else "hidden"

Template.sidebar.events
	"click .sidebarItem": (event) ->
		targetPosition = (Number) event.currentTarget.attributes["pos"].value
		classId = classes()[targetPosition - 1]._id unless targetPosition is 0
		
		Session.set "selectedClassPosition", targetPosition
		Session.set "selectedClassId", classId

		if targetPosition is 0 then Router.go "app" else Router.go "classView", classId: classId.toHexString()
		$(".slider").velocity top: targetPosition * 60, 150

	"click .sidebarFooterSettingsIcon": -> $("#settingsModal").modal()
	"click #addClassButton": ->
		$("#classNameInput").val("")
		$("#courseInput").val("")
		$("#bookInput").val("")
		$("#colorInput").colorpicker 'setValue', "#333"

		$("#addClassModal").modal()

	"click .sidebarFooterUserImage": -> window.open "http://en.gravatar.com/emails/",'_blank'

Template.sidebar.rendered = -> $("img.sidebarFooterUserImage").tooltip placement: "top", title: "Klik hier om je foto aan te passen"

# == End Sidebar ==

Template.app.contentOffsetLeft = -> if Session.get "isPhone" then "0" else "200px"

Template.app.rendered = ->
	notify("Je hebt je account nog niet geverifiëerd!") unless Meteor.user().emails[0].verified

	setChatHead()

	new AppScroll(
		scroller: $(".content")[0]
		#toolbar: $("#adbar")[0]
	).on()

	Deps.autorun ->
		if Meteor.user()? and !Meteor.user().hasPremium
			Meteor.defer ->
				if !Session.get "adsAllowed"
					Router.go "launchPage"
					Meteor.logout()
					alertModal "Adblock :c", 'Om simplyHomework gratis beschikbaar te kunnen houden zijn we afhankelijk van reclame-inkomsten.\nOm simplyHomework te kunnen gebruiken, moet je daarom je AdBlocker uitzetten.\nWil je toch simplyHomework zonder reclame gebruiken, kan je <a href="/">premium</a> nemen.'

	setSwipe() if Session.get "isPhone"

	if !amplify.store("allowCookies") and $(".cookiesContainer").length is 0
		UI.insert UI.render(Template.cookies), $("body").get()[0]
		$(".cookiesContainer").css visibility: "initial"
		$(".cookiesContainer").velocity { bottom: 0 }, 1200, "easeOutExpo"
		$("#acceptCookiesButton").click ->
			amplify.store "allowCookies", yes
			$(".cookiesContainer").velocity { bottom: "-500px" }, 2400, "easeOutExpo", -> $(".cookiesContainer").remove()

setSwipe = ->
	snapper = new Snap
		element: $(".content")[0]
		maxPosition: 200
		flickThreshold: 45
		minPosition: 0
		resistance: .9

	snapper.on "end", -> Session.set "sidebarOpen", snapper.state().state is "left"
	snapper.on "animated", -> Session.set "sidebarOpen", snapper.state().state is "left"

	$(".sidebarItem").click -> snapper.close()

setChatHead = ->
	el = $(".chatHead")

	@springs = {}

	@system = new rebound.SpringSystem()

	snap = (value, side) ->
		switch side
			when "top" then el.css transform: "translate3d(0px, #{value}px, 0px)"
			when "left" then el.css transform: "translate3d(#{value}px, 0px, 0px)"
			when "right" then el.css transform: "translate3d(#{$(window).width() + value}px, 0px, 0px)"
			when "bottom" then el.css transform: "translate3d(0px, #{$(window).height() + value}px, 0px)"

	scale = (value) -> $(".chatHeadBin").css transform: "scale(#{value})"

	springs.top = system.createSpring 40, 6
	springs.left = system.createSpring 40, 6
	springs.right = system.createSpring 40, 6
	springs.bottom = system.createSpring 40, 6
	springs.bin = system.createSpring 80, 3
	springs.top.addListener
		onSpringUpdate: (spring) ->
			val = spring.getCurrentValue()
			val = rebound.MathUtil.mapValueInRange val, 0, 1, 1, -20
			snap val, "top"
	springs.left.addListener
		onSpringUpdate: (spring) ->
			val = spring.getCurrentValue()
			val = rebound.MathUtil.mapValueInRange val, 0, 1, 1, -20
			snap val, "left"
	springs.right.addListener
		onSpringUpdate: (spring) ->
			val = spring.getCurrentValue()
			val = rebound.MathUtil.mapValueInRange val, 0, 1, 1, -40
			snap val, "right"
	springs.bottom.addListener
		onSpringUpdate: (spring) ->
			val = spring.getCurrentValue()
			val = rebound.MathUtil.mapValueInRange val, 0, 1, 1, -40
			snap val, "bottom"
	springs.bin.addListener
		onSpringUpdate: (spring) ->
			val = spring.getCurrentValue()
			val = rebound.MathUtil.mapValueInRange val, 0, 1, 1, 1.35
			scale val

	if !amplify.store("chatHeadInfo")? then amplify.store "chatHeadInfo", top: 253, left: 0, side: "right"
	chatHeadInfo = amplify.store "chatHeadInfo"
	$(".chatHead").css visibility: "hidden"

	@flingChatHeadsOnScreen = ->
		$(".chatHead").css top: 0, left: 0

		if chatHeadInfo.side is "left"
			$(".chatHead").css top: chatHeadInfo.top, visibility: "initial"
			springs.left.setCurrentValue(100).setAtRest()
			springs.left.setEndValue 1
			$(".chatHeadBadge").addClass "right"

			for follower, i in $(".chatHeadFollower")
				do (follower, i) ->
					follower.style.top = "#{chatHeadInfo.top + ( 5 * (i + 1) )}px"
					follower.style.zIndex = 99999 - i

		else if chatHeadInfo.side is "right"
			$(".chatHead").css top: chatHeadInfo.top, visibility: "initial"
			springs.right.setCurrentValue(-50).setAtRest()
			springs.right.setEndValue 1

			for follower, i in $(".chatHeadFollower")
				do (follower, i) ->
					follower.style.top = "#{chatHeadInfo.top + ( 5 * (i + 1) )}px"
					follower.style.zIndex = 99999 - i

		else if chatHeadInfo.side is "top"
			$(".chatHead").css left: chatHeadInfo.left, visibility: "initial"
			springs.top.setCurrentValue(100).setAtRest()
			springs.top.setEndValue 1
			$(".chatHeadBadge").addClass "under"

			for follower, i in $(".chatHeadFollower")
				do (follower, i) ->
					follower.style.left = "#{chatHeadInfo.left + ( 5 * (i + 1) )}px"
					follower.style.zIndex = 99999 - i

		else if chatHeadInfo.side is "bottom"
			$(".chatHead").css left: chatHeadInfo.left, visibility: "initial"
			springs.bottom.setCurrentValue(-50).setAtRest()
			springs.bottom.setEndValue 1

			for follower, i in $(".chatHeadFollower")
				do (follower, i) ->
					follower.style.left = "#{chatHeadInfo.left + ( 5 * (i + 1) )}px"
					follower.style.zIndex = 99999 - i

	delayIds = []

	$(".chatHeadLeader").draggable
		scroll: no
		start: ->
			springs.top.setAtRest()
			springs.left.setAtRest()
			springs.right.setAtRest()
			springs.bottom.setAtRest()
			$(".chatHeadFollower").css opacity: 0 # fix ugly glitch
			
			$(".chatHeadBinBack").css visibility: "initial"
			$(".chatHeadBinBack").velocity {bottom: 0}, 200, "easeOutExpo", ->
				$(".chatHeadBin").velocity {opacity: 1}, 200
		drag: ->
			top = (Number) $(".chatHeadLeader").css("top").replace /[^\d\.\-]/ig, ""
			left = (Number) $(".chatHeadLeader").css("left").replace /[^\d\.\-]/ig, ""

			springs.top.setCurrentValue(top / -20).setAtRest()
			springs.left.setCurrentValue(left / -20).setAtRest()
			springs.right.setCurrentValue(($(window).width() - left) / 40).setAtRest()
			springs.bottom.setCurrentValue(($(window).height() - top) / 40).setAtRest()
			
			$(".chatHeadBadge").removeClass "under"
			$(".chatHeadBadge").removeClass "right"
			$(".chatHead").css transform: "translate3d(0px, 0px, 0px)"

			for i in [0...$(".chatHeadFollower").length]
				do (i, top, left) ->
					func = ->
						follower = $(".chatHeadFollower")[i]
						follower.style.opacity = 1
						follower.style.left = "#{left + 4 * (i + 1)}px"
						follower.style.top = "#{top}px"
						follower.style.zIndex = 99999 - i
					delayIds.push Meteor.setTimeout func, 20 * (i + 1)
		stop: ->
			$(".chatHeadBin").velocity {opacity: 0}, 200, ->
				$(".chatHeadBinBack").velocity {bottom: "-500px"}, 350, ->
					$(this).css visibility: "hidden"
			Meteor.clearTimeout delayId for delayId in delayIds
			delayIds = []

			top = (Number) $(".chatHeadLeader").css("top").replace /[^\d\.\-]/ig, ""
			left = (Number) $(".chatHeadLeader").css("left").replace /[^\d\.\-]/ig, ""

			for i in [0...$(".chatHeadFollower").length]
				do (i, top, left) ->
					follower = $(".chatHeadFollower")[i]
					follower.style.left = "#{left + ( 5 * (i + 1))}px"
					follower.style.top = "#{top + ( 5 * (i + 1))}px"
					follower.style.zIndex = 99999 - i

			values = [{ side: "top", value: top }
				{ side: "left", value: left }
				{ side: "right", value: $(window).width() - left }
				{ side: "bottom", value: $(window).height() - top }
			]

			closest = _.first(_.sortBy(values, (v) -> v.value)).side
			value = _.first(_.sortBy(values, (v) -> v.value)).value

			if closest is "top"
				springs[closest].setCurrentValue(value / -20).setAtRest()
				$(".chatHead").css top: 0
				$(".chatHeadBadge").addClass "under"
				amplify.store "chatHeadInfo", { top, left, side: closest } unless $(".chatHead").hasClass "ignoreDrag"

			else if closest is "left"
				springs[closest].setCurrentValue(value / -20).setAtRest()
				$(".chatHead").css left: 0
				$(".chatHeadBadge").addClass "right"
				amplify.store "chatHeadInfo", { top, left, side: closest } unless $(".chatHead").hasClass "ignoreDrag"

			else if closest is "right"
				springs[closest].setCurrentValue(value / 40).setAtRest()
				$(".chatHead").css left: 0
				amplify.store "chatHeadInfo", { top, left, side: closest } unless $(".chatHead").hasClass "ignoreDrag"

			else if closest is "bottom"
				springs[closest].setCurrentValue(value / 40).setAtRest()
				$(".chatHead").css top: 0
				amplify.store "chatHeadInfo", { top, left, side: closest } unless $(".chatHead").hasClass "ignoreDrag"

			springs[closest].setEndValue 1

	$(".chatHeadBin").droppable
		over: ->
			springs.bin.setEndValue 1
			$(".chatHeadBin").css color: "red", borderColor: "red"
		out: ->
			springs.bin.setEndValue 0
			$(".chatHeadBin").css color: "white", borderColor: "white"
		drop: ->
			$(".chatHeadBin").css color: "white", borderColor: "white"
			springs.bin.setEndValue 0
			$(".chatHead").addClass("ignoreDrag")
			$(".chatHead").velocity {opacity: 0}, ->
				$(".chatHead").css(visibility: "hidden", opacity: 1)
				$(".chatHead").removeClass("ignoreDrag")