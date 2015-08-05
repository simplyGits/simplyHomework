currentSelectedSchool = null

doneQueries = []
schools = []
getSchools = (query, callback) ->
	if query.length < 3 or query in doneQueries
		_.defer callback, _.filter schools, (school) ->
			Helpers.contains school.name, query, yes
	else
		Meteor.call 'getServiceSchools', 'magister', query, (e, r) ->
			if e?
				callback []
			else
				doneQueries.push query
				schools = _(schools)
					.concat r
					.uniq 'name'
					.value()
				callback r

Template.magisterInfoModal.events
	'click #goButton': ->
		$magisterInfoModal = $ '#magisterInfoModal'
		schoolName = Helpers.cap $('#schoolNameInput').val()
		school = currentSelectedSchool

		getSchools schoolName, (r) =>
			school ?= _.first r
			username = $('#magisterUsernameInput').val().trim()
			password = $('#magisterPasswordInput').val()

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
							if e.error is 'forbidden' then 'Gebruikersnaam of wachtwoord onjuist.'
							else "Magister: '#{e.details}'"
						), 'error'
					else
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
