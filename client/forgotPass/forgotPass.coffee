Template.forgotPass.events
	'keydown': (event) ->
		email = event.target.value.toLowerCase()
		$emailInput = $ '#forgotPass > input'

		if event.which isnt 13
			$emailInput.tooltip 'destroy'
			document.getElementById('hint').className = 'visible'
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
