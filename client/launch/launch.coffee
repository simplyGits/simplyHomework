login = ->
	$emailInput = $ '#emailInput'
	$passwordInput = $ '#passwordInput'
	$passwordRepeatInput = $ '#passwordRepeatInput'

	Meteor.call 'mailExists', $emailInput.val().toLowerCase(), (error, result) ->
		if result
			Meteor.loginWithPassword $emailInput.val().toLowerCase(), $passwordInput.val(), (error) ->
				if error?
					if error.reason is 'Incorrect password'
						setFieldError '#passwordGroup', 'Wachtwoord is fout'
					else
						shake '#signupModal'
				else Router.go 'app'

		else
			error = no
			if empty $emailInput, '#emailGroup', 'Email is leeg' then error = yes
			else if not Helpers.correctMail $emailInput.val()
				setFieldError '#emailGroup', 'Ongeldig email adres'
				error = yes

			if empty $passwordInput, '#passwordGroup', 'Wachtwoord is leeg' then error = yes
			else if empty $passwordRepeatInput, '#passwordRepeatGroup', 'Wachtwoord is leeg' then error = yes
			else unless $passwordRepeatInput.val() is $passwordInput.val()
				setFieldError '#passwordRepeatGroup', 'Wachtwoorden komen niet overéén'
				error = yes

			unless error
				Accounts.createUser {
					password: $passwordInput.val()
					email: $emailInput.val().toLowerCase()
					profile:
						firstName: ''
						lastName: ''
				}, (e, r) ->
					if e?
						shake '#signupModal'
						notify 'Onbekende fout, we zijn op de hoogte gesteld.', 'error'
						Kadira.trackError 'create-account', e.message, stacks: e.stack
					else
						$('#signupModal').modal 'hide'
						Router.go 'setup'

Template.page1.helpers
	showQuickLoginhint: -> amplify.store('allowCookies')?

Template.signupModal.helpers
	creatingAccount: -> Session.get 'creatingAccount'

checkedMails = {}
Template.signupModal.events
	'keyup': (event) ->
		$emailInput = $ '#emailInput'
		$emailGroup = $ '#emailGroup'
		value = $emailInput.val().toLowerCase()

		unless event.which is 13
			if Helpers.correctMail value
				$emailGroup
					.removeClass 'error'
					.addClass 'success'
			else
				$emailGroup
					.removeClass 'success'
					.addClass 'error'

			if (val = checkedMails[value])?
				Session.set 'creatingAccount', val
			else if value.length > 3
				Meteor.call 'mailExists', value, (error, result) ->
					checkedMails[value] = not result
					Session.set 'creatingAccount', not result

	'keyup #passwordInput': (event) ->
		strength = Helpers.passwordStrength event.target.value
		len = event.target.value.length
		$('#passwordGroup')
			.removeClass 'error warning success'
			.addClass switch
				when not Session.get('creatingAccount') then ''

				when len is 0 then ''
				when 0 <= strength < 20 then 'error'
				when 20 <= strength < 60 then 'warning'
				else 'success'

	'keyup #passwordRepeatInput': (event) ->
		password = $('#passwordInput').val()
		return unless password.length > 0

		$(event.target.parentNode)
			.removeClass 'error success'
			.addClass (
				if event.target.value.length is 0
					''
				else if event.target.value is password
					'success'
				else
					'error'
			)

	'submit form': (event) ->
		event.preventDefault()
		login()

Template.page1.events
	'click #signupButton': ->
		Session.set 'creatingAccount', false
		showModal 'signupModal'

	'click #moreInfoButton': ->
		$('body').stop().animate {
			scrollTop: $('#page2').offset().top
		}, 1200, 'easeOutExpo'

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
	'click #page1': ->
		if $('#page2').hasClass 'topShadow'
			$('body').stop().animate {
				scrollTop: 0
			}, 600, 'easeOutExpo'

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
			$signUpForm
				.find 'input#username'
				.val String.fromCharCode event.which
				.focus()
		), 45

	$('body').on 'input', (event) ->
		return unless $('.signupForm input#username').val() is '' and $('.signupForm input#password').val() is ''
		$signUpForm.find('input').blur()

		$signUpForm.css( 'visibility': 'hidden' )
		$('.Center, .signupForm').removeClass('active')

	# sexy shadow, you like that, don't ya ;)
	page2 = $ '#page2'
	$(window).scroll ->
		if $(this).scrollTop() > 40
			page2.addClass('topShadow')
		else
			page2.removeClass('topShadow')
