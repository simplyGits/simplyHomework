loading = new ReactiveVar no

tfaData = new ReactiveVar undefined # { mail, password }

Template['login_signup'].helpers
	loggingIn: -> FlowRouter.getRouteName() is 'login'
	tfa: -> tfaData.get()?

	isLoading: -> loading.get()
	__loading: -> if loading.get() then 'loading' else ''

Template.login.events
	'submit': (event) ->
		event.preventDefault()
		$emailInput = $ '#emailInput'
		$passwordInput = $ '#passwordInput'

		mail = $emailInput.val().toLowerCase()
		password = $passwordInput.val()

		loading.set yes
		ga 'send', 'event', 'login'
		Meteor.loginWithPassword mail, password, (error) ->
			loading.set no
			if error?
				Meteor.defer ->
					if error.reason is 'Incorrect password'
						setFieldError '#passwordGroup', 'Wachtwoord is fout'
						$passwordInput.focus()
					else if error.reason is 'User not found'
						setFieldError '#emailGroup', 'Account niet gevonden'
						$emailInput.focus()
					else if error.error is 'tfa-required'
						tfaData.set { mail, password }
			else FlowRouter.go 'overview'

Template.login.onRendered ->
	setPageOptions
		title: 'Login'
		color: null

Template.tfa_login.onRendered ->
	@$('#tfaInput').focus()

Template.tfa_login.events
	'submit': (event) ->
		event.preventDefault()

		$tfaInput = $ '#tfaInput'
		token = $tfaInput.val().replace /[^0-9]/g, ''

		{ mail, password } = tfaData.get()
		loading.set yes
		Meteor.call 'tfa_login', mail, Package.sha.SHA256(password), token, (e, r) ->
			if e?
				loading.set no
				Meteor.defer ->
					setFieldError '#tfaGroup', 'Code is fout'
					$tfaInput.focus()
			else
				Meteor.loginWithToken r.token, (e, r) ->
					loading.set no
					tfaData.set undefined

					if e?
						notify 'Onbekende fout, we zijn op de hoogte gesteld', 'error'
						Kadira.trackError '2fa-login', e.message, stacks: e.stack
					else
						FlowRouter.go 'overview'

Template.signup.events
	'submit': (event) ->
		event.preventDefault()
		$emailInput = $ '#emailInput'
		$passwordInput = $ '#passwordInput'
		$passwordRepeatInput = $ '#passwordRepeatInput'

		error = no
		if empty $emailInput, '#emailGroup', 'Email is leeg' then error = yes
		else if not Helpers.validMail $emailInput.val()
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
					Meteor.defer ->
						if e.reason is 'Email already exists.'
							setFieldError '#emailGroup', 'Er is al account met deze email'
							$emailInput.focus()
						else
							notify 'Onbekende fout, we zijn op de hoogte gesteld', 'error'
							Kadira.trackError 'create-account', e.message, stacks: e.stack
				else FlowRouter.go 'overview'

Template.signup.onRendered ->
	setPageOptions
		title: 'Account maken'
		color: null
