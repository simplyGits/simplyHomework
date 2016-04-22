###
Template.magisterInfoModal.events
	'click #goButton': ->
		$magisterInfoModal = $ '#magisterInfoModal'
		$schoolNameInput   = $ '#schoolNameInput'
		$usernameInput     = $ '#magisterUsernameInput'
		$passwordInput     = $ '#magisterPasswordInput'

		any = no
		any = yes if empty $schoolNameInput, '#schoolNameGroup', 'Schoolnaam is leeg'
		any = yes if empty $usernameInput, '#usernameGroup', 'Gebruikersnaam is leeg'
		any = yes if empty $passwordInput, '#passwordGroup', 'Wachtwoord is leeg'
		return undefined if any

		schoolName = Helpers.cap $schoolNameInput.val()
		school = currentSelectedSchool

		getSchools schoolName, (r) =>
			school ?= _.first r
			username = $usernameInput.val().trim()
			password = $passwordInput.val()

			unless school?
				shake $magisterInfoModal
				notify "Geen school met de naam '#{schoolName}' gevonden", 'error'
				return undefined

			unless $('#allowGroup input').is ':checked'
				shake $magisterInfoModal
				setFieldError '#allowGroup', 'Je moet met de voorwaarden akkoord gaan om Magister te koppelen.'
				return undefined

			Meteor.call(
				'createServiceData',
				'magister',
				school.url,
				username,
				password,

				(e, r) =>
					if e?
						shake $magisterInfoModal
						notify (
							if e.error is 'forbidden' then 'Gebruikersnaam of wachtwoord onjuist'
							else if _.isString e.details then "Magister: '#{e.details}'"
							else 'Onbekende fout bij Magister opgetreden'
						), 'error'
					else
						r.schoolId = school._id
						@setProfileData r
						$magisterInfoModal.modal 'hide'
			)

Template.magisterInfoModal.onRendered ->
	$('#schoolNameInput')
		.focus()
		.typeahead {
			minLength: 2
		}, {
			displayKey: 'name'
			source: (query, callback) -> getSchools query, callback
		}
		.on 'typeahead:selected', (obj, datum) -> currentSelectedSchool = datum
###
