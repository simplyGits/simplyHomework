Template['settings_page_accountInfo'].helpers
	currentMail: -> getUserField Meteor.userId(), 'emails[0].address', ''

Template['settings_page_accountInfo'].events
	'click #deleteAccountButtonContainer > button': ->
		showModal 'deleteAccountModal'

	'submit form': (event) ->
		event.preventDefault()

		firstName = Helpers.nameCap $('#firstNameInput').val()
		lastName = Helpers.nameCap $('#lastNameInput').val()

		oldPass = $('#currentPassInput').val()

		mail = $('#mailInput').val().toLowerCase()

		newPass = $('#newPassInput').val()
		newPassRepeat = $('#newPassRepeatInput').val()

		profile = getUserField Meteor.userId(), 'profile'

		###*
		# Shows success / error message to the user.
		# @method callback
		# @param success {Boolean|null} If true show a success message, otherwise show an error message. If null, no message will be shown at all.
		###
		callback = (success) ->
			if success is yes
				swalert
					title: ':D'
					text: 'Je aanpassingen zijn successvol opgeslagen'
					type: 'success'

				$('#accountInfoSettings input[type="password"]').val ''

			else if success is no # sounds like sombody who sucks at English.
				swalert
					title: 'D:'
					text: 'Er is iets fout gegaan tijdens het opslaan van je instellingen.\nWe zijn op de hoogte gesteld.'
					type: 'error'

			undefined

		if mail isnt Meteor.user().emails[0].address
			if oldPass.length is 0
					setFieldError '#currentPassGroup', 'Geen wachtwoord ingevuld'
			else
				hash = Package.sha.SHA256 oldPass
				Meteor.call 'changeMail', mail, hash, (e) ->
					if e?.error is 'wrong-password'
						setFieldError '#currentPassGroup', 'Wachtwoord is fout'
					else
						callback not e?

		if profile.firstName isnt firstName or profile.lastName isnt lastName
			Meteor.call 'changeName', firstName, lastName, (e) -> callback not e?

		if oldPass isnt '' and newPass isnt ''
			unless newPass is newPassRepeat
				setFieldError '#newPassRepeatGroup'
				return

			Accounts.changePassword oldPass, newPass, (error) ->
				if error?
					if error.reason is 'Incorrect password'
						setFieldError '#oldPassGroup', 'Verkeerd wachtwoord'
					else
						Kadira.trackError 'changePassword-client', error.reason, stacks: EJSON.stringify error
						callback no

				else
					callback yes

Template.deleteAccountModal.events
	'click #goButton': ->
		$passwordInput = $ '#deleteAccountModal #passwordInput'
		captcha = $('#g-recaptcha-response').val()

		hash = Package.sha.SHA256 $passwordInput.val()
		Meteor.call 'removeAccount', hash, captcha, (e) ->
			if e?
				if e.error is 'wrongPassword'
					setFieldError $passwordInput, 'Verkeerd wachtwoord'
					grecaptcha.reset()
				else if e.error is 'wrongCaptcha'
					shake '#deleteAccountModal'
				else
					notify 'Oops, er is iets fout gegaan.', 'error'
			else
				ga 'send', 'event', 'remove account'
				document.location.href = 'https://simplyhomework.nl/'
