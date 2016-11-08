loading = new ReactiveVar no

tfaData = new ReactiveVar undefined # { mail, password }

Template['login_signup'].helpers
	template: ->
		if tfaData.get()?
			Template['tfa_login']
		else if FlowRouter.getRouteName() is 'forgotPass'
			Template['forgotPass_login']

	loggingIn: -> FlowRouter.getRouteName() is 'login'

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
		(
			if Helpers.validMail(mail) then Meteor.loginWithPassword
			else Meteor.loginWithExternalServices
		) mail, password, (error) ->
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

Template.forgotPass_login.events
	'submit': (event) ->
		event.preventDefault()

		$emailInput = $ '#emailInput'
		mail = $emailInput.val().toLowerCase().trim()

		if mail.length is 0
			setFieldError '#emailGroup', 'Email is leeg'
			return
		else if not Helpers.validMail mail
			setFieldError '#emailGroup', 'Ongeldig email adres'
			return

		Accounts.forgotPassword { email: mail }, (e) ->
			if e?
				if e.error is 403
					setFieldError '#emailGroup', 'Geen account met dit adres gevonden'
				else
					swalert
						title: 'Fout'
						text: 'Onbekende fout, we zijn op de hoogte gesteld'
						type: 'error'

					Kadira.trackError 'forgotPass-client', e.message, stacks: e.stack
			else
				swalert
					title: 'Mail verstuurd'
					text: 'Je krijgt zometeen een mailtje waar je je wachtwoord kan veranderen.'
					type: 'success'

Template.forgotPass_login.onRendered ->
	setPageOptions
		title: 'Wachtwoord Vergeten'
		color: null
