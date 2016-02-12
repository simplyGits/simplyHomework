loading = new ReactiveVar no

Template['login_signup'].helpers
	loggingIn: -> FlowRouter.getRouteName() is 'login'

	isLoading: -> loading.get()
	__loading: -> if loading.get() then 'loading' else ''

Template.login.events
	'submit': (event) ->
		event.preventDefault()
		$emailInput = $ '#emailInput'
		$passwordInput = $ '#passwordInput'

		loading.set yes
		ga 'send', 'event', 'login'
		Meteor.loginWithPassword $emailInput.val().toLowerCase(), $passwordInput.val(), (error) ->
			loading.set no
			if error?
				Meteor.defer ->
					if error.reason is 'Incorrect password'
						setFieldError '#passwordGroup', 'Wachtwoord is fout'
						$passwordInput.focus()
					else if error.reason is 'User not found'
						setFieldError '#emailGroup', 'Account niet gevonden'
						$emailInput.focus()
			else FlowRouter.go 'overview'

Template.login.onRendered ->
	setPageOptions
		title: 'Login'
		color: null

Template.signup.events
	'submit': ->
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

		unless $('#allowGroup input').is ':checked'
			setFieldError '#allowGroup', 'Je moet met de voorwaarden akkoord gaan.'
			error = yes

		unless error
			loading.set yes
			ga 'send', 'event', 'signup'
			Accounts.createUser {
				password: $passwordInput.val()
				email: $emailInput.val().toLowerCase()
			}, (e, r) ->
				loading.set no
				if e?
					notify 'Onbekende fout, we zijn op de hoogte gesteld.', 'error'
					Kadira.trackError 'create-account', e.message, stacks: e.stack
				else FlowRouter.go 'overview'

Template.signup.onRendered ->
	setPageOptions
		title: 'Account maken'
		color: null
