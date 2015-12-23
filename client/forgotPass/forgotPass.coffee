Template.forgotPass.events
	'keydown': (event) ->
		email = event.target.value.toLowerCase()
		$emailInput = $ '#forgotPass > input'

		if event.which isnt 13
			$emailInput.tooltip 'destroy'
			return undefined

		Accounts.forgotPassword { email }, (e) ->
			if e?
				if e.error is 403
					setFieldError $emailInput, 'Geen account met dit adres gevonden.'
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

Template.forgotPass.onRendered ->
	setPageOptions
		title: 'Wachtwoord Vergeten'
		color: null

Template.resetPass.events
	'submit': (event) ->
		event.preventDefault()
		val = document.getElementById('passwordInput').value

		Accounts.resetPassword FlowRouter.getParam('token'), val, (err) ->
			if err?
				if err.reason is 'Token expired'
					swalert
						title: 'Al gebruikt'
						html: 'Wachtwoord is al een keer veranderd met deze link. Klik <a href="/forgot">hier</a> als je je wachtwoord nog een keer wilt wijzingen.'
						type: 'error'
				else
					swalert
						title: 'Fout'
						text: 'Onbekende fout, we zijn op de hoogte gesteld'
						type: 'error'

					Kadira.trackError 'resetPass-client', err.message, stacks: EJSON.stringify err
			else
				FlowRouter.go 'overview'
				swalert
					title: 'yay'
					text: 'Je wachtwoord is aangepast.'
					type: 'success'

Template.resetPass.onRendered ->
	setPageOptions
		title: 'Wachtwoord Aanpassen'
		color: null
