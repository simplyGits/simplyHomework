Template['settings_page_accountInfo'].helpers
	currentMail: -> getUserField Meteor.userId(), 'emails[0].address', ''

Template['settings_page_accountInfo'].events
	'click #deleteAccountButtonContainer > button': ->
		showModal 'deleteAccountModal'

	'submit form': (event) ->
		event.preventDefault()

		mail = $('#mailInput').val().toLowerCase()

		firstName = Helpers.nameCap $('#firstNameInput').val()
		lastName = Helpers.nameCap $('#lastNameInput').val()

		oldPass = $('#oldPassInput').val()
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

			else if success is no # sounds like sombody who sucks at English.
				swalert
					title: 'D:'
					text: 'Er is iets fout gegaan tijdens het opslaan van je instellingen.\nWe zijn op de hoogte gesteld.'
					type: 'error'

			undefined

		if mail isnt Meteor.user().emails[0].address
			Meteor.call 'changeMail', mail, (e) -> callback not e?

		if profile.firstName isnt firstName or profile.lastName isnt lastName
			Meteor.users.update Meteor.userId(), {
				$set:
					'profile.firstName': firstName
					'profile.lastName': lastName
			}, (e) -> callback not e?

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
