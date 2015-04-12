login = ->
	if not Session.get "creatingAccount"
		Meteor.loginWithPassword $("#emailInput").val().toLowerCase(), $("#passwordInput").val(), (error) ->
			if error? and error.reason is "Incorrect password"
				$("#passwordGroup").addClass("error").tooltip(placement: "bottom", title: "Wachtwoord is fout", trigger: "manual").tooltip("show")
	else
		Meteor.call "mailExists", $("#emailInput").val().toLowerCase(), (error, result) ->
			if result
				Session.set "creatingAccount", no
				login()
			else
				okay = true
				if empty "emailInput", "emailGroup", "Email is leeg" then okay = false
				if empty "passwordInput", "passwordGroup", "Wachtwoord is leeg" then okay = false
				if empty "betaCodeInput", "betaCodeGroup", "Voornaam is leeg" then okay = false
				unless correctMail $("#emailInput").val()
					$("#emailGroup").removeClass("error").tooltip "destroy"
					$("#emailGroup").addClass("error").tooltip(placement: "bottom", title: "Ongeldig email adres", trigger: "manual").tooltip("show")
					okay = false
				if okay
					Accounts.createUser {
						password: $("#passwordInput").val()
						email: $("#emailInput").val().toLowerCase()
						profile:
							firstName: ""
							lastName: ""
							code: $("#betaCodeInput").val().trim().toLowerCase()
					}, (e, r) ->
						if e? then shake "#signupModal"
						else Meteor.call "callMailVerification", -> Router.go "app"

	Router.go "app" if Meteor.userId()? or Meteor.loggingIn()

Template.page1.helpers showQuickLoginhint: -> amplify.store("allowCookies")?

Template.signupModal.helpers creatingAccount: -> Session.get "creatingAccount"

Template.signupModal.events
	"keyup": (event) ->
		value = event.target.value

		unless event.which is 13
			if correctMail $("#emailInput").val()
				$("#emailGroup").removeClass "error"
				$("#emailGroup").addClass "success"
			else
				$("#emailGroup").removeClass "success"
				$("#emailGroup").addClass "error"

			unless value.length < 4
				Meteor.call "mailExists", $("#emailInput").val().toLowerCase(), (error, result) -> Session.set "creatingAccount", not result

	'submit form': (event) ->
		event.preventDefault()
		login()
	'keyup #passwordInput': (event) -> login() if event.which is 13

Template.page1.events
	'click #signupButton': ->
		Session.set "creatingAccount", false
		$("#signupModal").modal()

	'click .launchpageMoreInfoBottom': -> $("body").stop().animate {scrollTop: $('#page2').offset().top}, 1200, "easeOutExpo"

	"keyup input#password": (event) ->
		$(".signUpForm > .enterHint").velocity opacity: .7
		return unless event.which is 13

		Meteor.loginWithPassword $("input#username").val().toLowerCase(), $("input#password").val(), (error) ->
			if error? and error.reason is "Incorrect password"
				shake "input#password"
			else if error?
				shake "input"

			else Router.go "app"

Template.launchPage.events
	'click #page1': -> if $("#page2").hasClass("topShadow") then $("body").stop().animate {scrollTop: 0}, 600, "easeOutExpo"

Template.launchPage.rendered = ->
	@subscribe "userCount"

	signUpForm = @$ ".signUpForm"
	$("body").keypress (event) ->
		return if event.which is 13 or $("input").is ":focus"

		$("body").stop().animate {scrollTop: 0}, 600, "easeOutExpo"

		signUpForm.css( "visibility": "initial" )
		$(".Center, .signUpForm").addClass("active")
		_.delay ( ->
			signUpForm.find("input#username").val(String.fromCharCode event.which).focus()
		), 45

	$("body").on "input", (event) ->
		return unless $(".signUpForm input#username").val() is "" and $(".signUpForm input#password").val() is ""
		signUpForm.find("input").blur()

		signUpForm.css( "visibility": "hidden" )
		$(".Center, .signUpForm").removeClass("active")

	# sexy shadow, you like that, don't ya ;)
	page2 = $ "#page2"
	$(window).scroll ->
		if $(this).scrollTop() > 40
			page2.addClass("topShadow")
		else
			page2.removeClass("topShadow")
