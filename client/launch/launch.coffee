login = ->
	if not Session.get 'creatingAccount'
		Meteor.loginWithPassword $('#emailInput').val().toLowerCase(), $('#passwordInput').val(), (error) ->
			if error? and error.reason is 'Incorrect password'
				setFieldError '#passwordGroup', 'Wachtwoord is fout'
	else
		Meteor.call 'mailExists', $('#emailInput').val().toLowerCase(), (error, result) ->
			if result
				Session.set 'creatingAccount', no
				login()
			else
				okay = true
				if empty 'emailInput', 'emailGroup', 'Email is leeg' then okay = false
				if empty 'passwordInput', 'passwordGroup', 'Wachtwoord is leeg' then okay = false
				if empty 'betaCodeInput', 'betaCodeGroup', 'Voornaam is leeg' then okay = false
				unless correctMail $('#emailInput').val()
					group = $('#emailGroup').tooltip 'destroy'
					setFieldError group, 'Ongeldig email adres'
					okay = false
				if okay
					Accounts.createUser {
						password: $('#passwordInput').val()
						email: $('#emailInput').val().toLowerCase()
						profile:
							firstName: ''
							lastName: ''
							code: $('#betaCodeInput').val().trim().toLowerCase()
					}, (e, r) ->
						if e? then shake '#signupModal'
						else Meteor.call 'callMailVerification', -> Router.go 'app'

	Router.go 'app' if Meteor.userId()? or Meteor.loggingIn()

Template.page1.helpers showQuickLoginhint: -> amplify.store('allowCookies')?

Template.signupModal.helpers creatingAccount: -> Session.get 'creatingAccount'

Template.signupModal.events
	'keyup': (event) ->
		value = event.target.value

		unless event.which is 13
			if correctMail $('#emailInput').val()
				$('#emailGroup')
					.removeClass 'error'
					.addClass 'success'
			else
				$('#emailGroup')
					.removeClass 'success'
					.addClass 'error'

			unless value.length < 4
				Meteor.call 'mailExists', $('#emailInput').val().toLowerCase(), (error, result) -> Session.set 'creatingAccount', not result

	'keyup #passwordInput': (event) ->
		if event.which is 13 then login()
		else
			strength = Helpers.passwordStrength event.target.value
			len = event.target.value.length
			$('#passwordGroup')
				.removeClass 'error warning success'
				.addClass switch
					when len is 0 then ''
					when 0 <= strength < 20 then 'error'
					when 20 <= strength < 60 then 'warning'
					else 'success'

	'submit form': (event) ->
		event.preventDefault()
		login()

Template.page1.events
	'click #signupButton': ->
		Session.set 'creatingAccount', false
		$('#signupModal').modal()

	'click #moreInfoButton': -> $('body').stop().animate {scrollTop: $('#page2').offset().top}, 1200, 'easeOutExpo'

	'keyup input#password': (event) ->
		$('.signupForm > .enterHint').velocity opacity: .7
		return unless event.which is 13

		$input    = $ '.signupForm input'
		$username = $ '.signupForm input#username'
		$password = $ '.signupForm input#password'

		Meteor.loginWithPassword $username.val().toLowerCase(), $password.val(), (error) ->
			if error? and error.reason is 'Incorrect password'
				shake $password
			else if error?
				shake $input

			else Router.go 'app'

Template.launchPage.events
	'click #page1': -> if $('#page2').hasClass('topShadow') then $('body').stop().animate {scrollTop: 0}, 600, 'easeOutExpo'

Template.launchPage.rendered = ->
	@subscribe 'userCount'

	$signUpForm = @$ '.signupForm'
	$('body').keypress (event) ->
		hasModifier = event.altKey or event.ctrlKey or event.metaKey
		return if event.which < 32 or hasModifier or $('input').is ':focus'

		$('body').stop().animate { scrollTop: 0 }, 600, 'easeOutExpo'

		$signUpForm.css( 'visibility': 'initial' )
		$('.Center, .signupForm').addClass('active')
		_.delay ( ->
			$signUpForm.find('input#username').val(String.fromCharCode event.which).focus()
		), 45

	$('body').on 'input', (event) ->
		Meteor.setTimeout (->
			return unless $('.signupForm input#username').val() is '' and $('.signupForm input#password').val() is ''
			$signUpForm.find('input').blur()

			$signUpForm.css( 'visibility': 'hidden' )
			$('.Center, .signupForm').removeClass('active')
		), 500

	# sexy shadow, you like that, don't ya ;)
	page2 = $ '#page2'
	$(window).scroll ->
		if $(this).scrollTop() > 40
			page2.addClass('topShadow')
		else
			page2.removeClass('topShadow')
