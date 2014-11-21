login = ->
	if not Session.get "creatingAccount"
		Meteor.loginWithPassword $("#emailInput").val().toLowerCase(), $("#passwordInput").val(), (error) ->
			if error? and error.reason is "Incorrect password"
				$("#passwordGroup").addClass("has-error").tooltip(placement: "bottom", title: "Wachtwoord is fout").tooltip("show")
	else
		Meteor.call "mailExists", $("#emailInput").val().toLowerCase(), (error, result) ->
			if result
				Session.set "creatingAccount", no
				login()
			else
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
							firstName: Helpers.cap $("#firstNameInput").val().trim()
							lastName: Helpers.cap $("#lastNameInput").val().trim()
					Meteor.call "verifyMail"
					Meteor.users.update Meteor.userId(), $set: mailSignup: $("#mailSignupInput").prop("checked"), classInfos: []

Template.page1.helpers showQuickLoginhint: -> amplify.store("allowCookies")?
Template.launchPage.rendered = -> $("#simplyLogoIntro").attr "src", "images/simplyLogo.gif"

Template.signupModal.helpers creatingAccount: -> Session.get "creatingAccount"

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

	'click .launchpageMoreInfoBottom': -> $("body").stop().animate {scrollTop: $('#page2').offset().top}, 1200, "easeOutExpo"

	"keyup input#password": (event) ->
		return unless event.which is 13

		Meteor.loginWithPassword $("input#username").val().toLowerCase(), $("input#password").val(), (error) ->
			if error? and error.reason is "Incorrect password"
				$("input#password").addClass "animated shake"
				$('input#password').one 'webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', ->
					$("input#password").removeClass "animated shake"
			else if error?
				$(".signUpForm").addClass "animated shake"
				$('.signUpForm').one 'webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', ->
					$(".signUpForm").removeClass "animated shake"

Template.launchPage.events
	'click #page1': -> if $("#page2").hasClass("topShadow") then $("body").stop().animate {scrollTop: 0}, 600, "easeOutExpo"

Meteor.startup ->
	Meteor.defer -> Deps.autorun -> if Meteor.user()? and Router.current().route.getName() is "launchPage" then Router.go "app"

	$("body").keypress (event) ->
		return if event.which is 13 or $("input").is ":focus"

		$(".signUpForm").css( "visibility": "initial" )
		$(".Center, .signUpForm").addClass("active")
		_.delay ( ->
			$(".signUpForm input#username").val(String.fromCharCode event.which).focus()
		), 25

	$("body").on "input", (event) ->
		return unless $(".signUpForm input#username").val() is "" and $(".signUpForm input#password").val() is ""
		$(".signUpForm input").blur()

		$(".signUpForm").css( "visibility": "hidden" )
		$(".Center, .signUpForm").removeClass("active")

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