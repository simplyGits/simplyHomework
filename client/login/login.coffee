# Accounts.createUser {
# 	password: $passwordInput.val()
# 	email: $emailInput.val().toLowerCase()
# 	profile:
# 		firstName: ''
# 		lastName: ''
# }, (e, r) ->
# 	if e?
# 		shake '#signupModal'
# 		notify 'Onbekende fout, we zijn op de hoogte gesteld.', 'error'
# 		Kadira.trackError 'create-account', e.message, stacks: e.stack
# 	else
# 		$('#signupModal').modal 'hide'
# 		FlowRouter.go 'overview'

serverMailExists = _.throttle ((mail, callback) ->
	Meteor.call 'mailExists', mail, (error, result) -> callback result
), 150

checkedMails = {}
mailExists = (mail, callback) ->
	checked = checkedMails[mail]
	if checked? then callback checked

	else if mail.length > 3
		serverMailExists mail, (exists) ->
			checkedMails[mail] = exists
			callback exists

	undefined

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
						setFieldError '#emailGroup', 'Account niet gevonden'
				else FlowRouter.go 'overview'

		else
			error = no
			if empty $emailInput, '#emailGroup', 'Email is leeg' then error = yes
			else if not Helpers.correctMail $emailInput.val()
				setFieldError '#emailGroup', 'Ongeldig email adres'
				error = yes

			if empty $passwordInput, '#passwordGroup', 'Wachtwoord is leeg' then error = yes


Template.login.events
	# 'keyup': (event) ->
	# 	$emailInput = $ '#emailInput'
	# 	$emailGroup = $ '#emailGroup'
	# 	value = $emailInput.val().toLowerCase()

	# 	unless event.which is 13
	# 		if Helpers.correctMail value
	# 			$emailGroup
	# 				.removeClass 'error'
	# 				.addClass 'success'
	# 		else
	# 			$emailGroup
	# 				.removeClass 'success'
	# 				.addClass 'error'

	# 		mailExists value, (exists) -> Session.set 'creatingAccount', not exists

	# 'keyup #passwordInput': (event) ->
	# 	strength = Helpers.passwordStrength event.target.value
	# 	len = event.target.value.length
	# 	$('#passwordGroup')
	# 		.removeClass 'error warning success'
	# 		.addClass switch
	# 			when not Session.get('creatingAccount') then ''

	# 			when len is 0 then ''
	# 			when 0 <= strength < 20 then 'error'
	# 			when 20 <= strength < 60 then 'warning'
	# 			else 'success'

	'submit form': (event) ->
		event.preventDefault()
		login()

Template.login.onRendered ->
	setPageOptions
		title: 'simplyHomework | Login'
		useAppPrefix: no
		color: null