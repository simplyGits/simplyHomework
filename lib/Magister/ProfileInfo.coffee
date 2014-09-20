class @ProfileInfo
	constructor: (@_magisterObj, @_firstName, @_lastName, @_birthDate) ->
		@id = _getset "_id"
		@officialFirstNames = _getset "_officialFirstNames"
		@initials = _getset "_initials"
		@namePrefix = _getset "_namePrefix"
		@officialSurname = _getset "_officialSurname"
		@birthSurname = _getset "_birthSurname"
		@birthNamePrefix = _getset "_birthNamePrefix"
		@useBirthname = _getset "_useBirthname"
		@firstName = _getset "_firstName"
		@lastName = _getset "_lastName"
		@profilePicture = _getset "_profilePicture"

	@_convertRaw: (magisterObj, raw) ->
		foto = magisterObj.magisterSchool.url + _.find(raw.Links, Rel: "Foto").Href

		raw = raw.Persoon
		obj = new ProfileInfo magisterObj, raw.Roepnaam, raw.Achternaam, new Date Date.parse raw.Geboortedatum
		
		obj._id = raw.Id
		obj._officialFirstNames = raw.OfficieleVoornamen
		obj._initials = raw.Voorletters
		obj._namePrefix = raw.Tussenvoegsel
		obj._officialSurname = raw.OfficieleAchternaam
		obj._birthSurname = raw.GeboorteAchternaam
		obj._birthNamePrefix = raw.GeboortenaamTussenvoegsel
		obj._useBirthname = raw.GebruikGeboortenaam
		obj._profilePicture = foto

		return obj