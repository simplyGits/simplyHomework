Template.zermeloInfoModal.events
	'click #goButton': ->
		$zermeloInfoModal = $ '#zermeloInfoModal'
		$schoolidInput     = $ '#schoolidInput'
		$authcodeInput     = $ '#authcodeInput'

		error = no
		error = yes if empty $schoolidInput, '#schoolidGroup', 'School id is leeg'
		error = yes if empty $authcodeInput, '#authcodeGroup', 'Toegangscode is leeg'
		return undefined if error

		schoolid = $schoolidInput.val().trim()
		authcode = $authcodeInput.val().trim()

		Meteor.call(
			'createServiceData'
			'zermelo'
			schoolid
			authcode
			(e, r) =>
				if e?
					shake $zermeloInfoModal
					notify (
						if e.error is 'forbidden' then 'Toegangscode onjuist'
						else if _.isString e.details then "Zermelo: '#{e.details}'"
						else 'Onbekende fout bij Zermelo opgetreden'
					), 'error'
				else
					@setProfileData r
					$zermeloInfoModal.modal 'hide'
		)
