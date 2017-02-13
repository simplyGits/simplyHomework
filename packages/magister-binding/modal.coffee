loading = new ReactiveVar no
currentSelectedSchool = null

doneQueries = []
schools = []
getSchools = (query, syncCallback, asyncCallback) ->
	asyncCallback ?= syncCallback
	if query.length < 3 or query in doneQueries
		syncCallback _.filter schools, (school) ->
			Helpers.contains school.name, query, yes
	else
		Meteor.call 'getServiceSchools', 'magister', query, (e, r) ->
			if e?
				asyncCallback []
			else
				doneQueries.push query
				schools = _(schools)
					.concat r
					.uniq 'name'
					.value()
				asyncCallback r

Template.magisterInfoModal.helpers
	isLoading: -> loading.get()

Template.magisterInfoModal.events
	'click #goButton': ->
		$magisterInfoModal = $ '#magisterInfoModal'
		$schoolNameInput   = $ '#schoolNameInput'
		$usernameInput     = $ '#magisterUsernameInput'
		$passwordInput     = $ '#magisterPasswordInput'

		error = no
		error = yes if empty $schoolNameInput, '#schoolNameGroup', 'Schoolnaam is leeg'
		error = yes if empty $usernameInput, '#usernameGroup', 'Gebruikersnaam is leeg'
		error = yes if empty $passwordInput, '#passwordGroup', 'Wachtwoord is leeg'
		return undefined if error

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

			loading.set yes
			Meteor.call(
				'createServiceData',
				'magister',
				school.externalInfo.magister.url,
				username,
				password,

				(e, r) =>
					loading.set no
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
			async: yes
			source: getSchools
			display: 'name'
		}
		.on 'typeahead:selected', (obj, datum) -> currentSelectedSchool = datum
