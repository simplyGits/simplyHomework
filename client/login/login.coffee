login = ->
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


Template.login.events
	'submit form': (event) ->
		event.preventDefault()
		login()

Template.login.onRendered ->
	setPageOptions
		title: 'simplyHomework | Login'
		useAppPrefix: no
		color: null
