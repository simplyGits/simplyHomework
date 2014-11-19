@Locals =
	"nl-NL":
		# TextToSpeech
		TtsTimeStartExact: (vakNaam, uur, minuten) -> return "#{vakNaam} begint om #{uur} uur #{minuten}." # example: Geschiedenis begint om 2 uur 35.
		TtsTimeStartRelative: (vakNaam, minuten) -> return "#{vakNaam} begint over #{minuten} minuten." # example: Geschiedenis begint over 50 minuten.
		TtsTimeToLeaveExact: (uur, minuten, vakNaam) -> return "Je moet om #{uur} uur #{minuten} weg voor #{vakNaam}." # example: Je moet om 2 uur 35 weg voor scheikunde.
		TtsTimeToLeaveRelative: (minuten, vakNaam) -> return "Je moet over #{minuten} minute(n) weg voor #{vakNaam}." # example: Je moet over 1 minuut weg voor scheikunde.
		GreetingMessage: ->
			"simplyHomework is een automatische huiswerkplanner die je leven makkelijker maakt.\n\n" +
			
			"Het haalt automatisch je huiswerk van magister, zoekt de juiste woordenlijsten bij het huiswerk, plant automatisch voor proefwerken en nog veel meer.\n\n" +
			
			"Voordat we beginnen hebben we nog een paar vraagjes."
		ProjectPersonRemovalMessage: (name) -> "Je staat op het punt om <b>#{escape name}</b> te verwijderen.\nWe wilden even zeker weten of dit de bedoeling was."
		ProjectPersonRemovedNotice: (name) -> "#{name} verwijderd."
		ProjectPersonAddedNotice: (name) -> "#{name} toegevoegd."