Template['login_signup'].helpers
	loggingIn: -> FlowRouter.getRouteName() is 'login'

Template.login.events
	'submit form': (event) ->
		event.preventDefault()
		$emailInput = $ '#emailInput'
		$passwordInput = $ '#passwordInput'

		Meteor.call 'mailExists', $emailInput.val().toLowerCase(), (error, result) ->
			if result
				Meteor.loginWithPassword $emailInput.val().toLowerCase(), $passwordInput.val(), (error) ->
					if error?
						if error.reason is 'Incorrect password'
							setFieldError '#passwordGroup', 'Wachtwoord is fout'
					else FlowRouter.go 'overview'

			else
				setFieldError '#emailGroup', 'Account niet gevonden'

Template.login.onRendered ->
	setPageOptions
		title: 'Login'
		color: null

Template.signup.events
	'submit form': ->
		event.preventDefault()
		$emailInput = $ '#emailInput'
		$passwordInput = $ '#passwordInput'
		$passwordRepeatInput = $ '#passwordRepeatInput'

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
			}, (e, r) ->
				if e?
					notify 'Onbekende fout, we zijn op de hoogte gesteld.', 'error'
					Kadira.trackError 'create-account', e.message, stacks: e.stack
				else FlowRouter.go 'overview'

Template.signup.onRendered ->
	setPageOptions
		title: 'Account maken'
		color: null
