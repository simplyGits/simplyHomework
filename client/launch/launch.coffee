login = ->
	if !Session.get "creatingAccount"
		Meteor.loginWithPassword $("#emailInput").val().toLowerCase(), $("#passwordInput").val(), (error) ->
			if error? and error.reason is "Incorrect password"
				$("#passwordGroup").addClass("has-error").tooltip(placement: "bottom", title: "Wachtwoord is fout").tooltip("show")
	else
		Meteor.call "mailExists", $("#emailInput").val().toLowerCase(), (error, result) ->
			if result
				Session.set "creatingAccount", no
				login()
		okay = true
		if empty "emailInput", "emailGroup", "Email is leeg" then okay = false
		if empty "passwordInput", "passwordGroup", "Wachtwoord is leeg" then okay = false
		if empty "firstNameInput", "firstNameGroup", "Voornaam is leeg" then okay = false
		if empty "lastNameInput", "lastNameGroup", "Achternaam is leeg" then okay = false
		unless correctMail $("#emailInput").val()
			$("#emailGroup").removeClass("has-error").tooltip "destroy"
			$("#emailGroup").addClass("has-error").tooltip(placement: "bottom", title: "Ongeldig email adres").tooltip("show")
			okay = false
		if okay
			Accounts.createUser
				password: $("#passwordInput").val()
				email: $("#emailInput").val().toLowerCase()
				profile:
					firstName: Helpers.cap $("#firstNameInput").val()
					lastName: Helpers.cap $("#lastNameInput").val()
			Meteor.call "verifyMail"
			Meteor.users.update Meteor.userId(), $set: mailSignup: $("#mailSignupInput").prop("checked"), classInfos: []

Meteor.startup ->
	Meteor.defer -> Deps.autorun -> if Meteor.user()? and Router.current().route.name is "launchPage" then Router.go "app"

	Template.launchPage.rendered = -> $("#simplyLogoIntro").attr "src", "images/simplyLogo.gif"
	Template.signupModal.creatingAccount = -> Session.get "creatingAccount"

	Template.signupModal.events
		'keyup #emailInput': (evt) ->
			value = evt.target.value
			unless evt.which is 13
				if correctMail $("#emailInput").val()
					$("#emailGroup").removeClass "has-error"
					$("#emailGroup").addClass "has-success"
				else
					$("#emailGroup").removeClass "has-success"
					$("#emailGroup").addClass "has-error"
				unless value.length < 4
					Meteor.call "mailExists", $("#emailInput").val().toLowerCase(), (error, result) -> Session.set "creatingAccount", not result

		'submit form': (event) ->
			event.preventDefault()
			login()
		'click #createAccountButton': -> Session.set "creatingAccount", true
		'keyup #passwordInput': (evt) -> login() if evt.which is 13 and !Session.get "creatingAccount"

	Template.page1.events
		'click #signupButton': ->
			Session.set "creatingAccount", false
			$("#signupModal").modal()

		'click .launchpageMoreInfoBottom': -> $("body").animate {scrollTop: $('#page2').offset().top}, 1200, "easeOutExpo"
	Template.launchPage.events
		'click #page1': -> if $("#page2").hasClass("topShadow") then $("body").animate {scrollTop: 0}, 600, "easeOutExpo"

	# sexy shadow, you like that, don't ya ;)
	$(window).scroll ->
		scroll = $(window).scrollTop()
		if scroll > 40
			$("#page2").addClass("topShadow")
		else
			$("#page2").removeClass("topShadow")

		# unless Session.get "isPhone"
		# 	scrollDelta = ($("#page2").offset().top - scroll) / $("#page2").offset().top
		# 	opacity = 1 - scrollDelta
		# 	marginTop = 20 + 280 * scrollDelta
		# 	$(".card").css
		# 		opacity: opacity
		# 		marginTop: "#{marginTop}px"