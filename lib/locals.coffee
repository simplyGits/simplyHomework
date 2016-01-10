@Locals =
	"nl-NL":
		# TextToSpeech
		TtsTimeStartExact: (vakNaam, uur, minuten) -> "#{vakNaam} begint om #{uur} uur #{minuten}." # example: Geschiedenis begint om 2 uur 35.
		TtsTimeStartRelative: (vakNaam, minuten) -> "#{vakNaam} begint over #{minuten} minuten." # example: Geschiedenis begint over 50 minuten.
		TtsTimeToLeaveExact: (uur, minuten, vakNaam) -> "Je moet om #{uur} uur #{minuten} weg voor #{vakNaam}." # example: Je moet om 2 uur 35 weg voor scheikunde.
		TtsTimeToLeaveRelative: (minuten, vakNaam) -> "Je moet over #{minuten} minute(n) weg voor #{vakNaam}." # example: Je moet over 1 minuut weg voor scheikunde.

		ProjectPersonRemovalMessage: (name) ->
			"""
				Je staat op het punt om <b>#{_.escape name}</b> te verwijderen.
				We wilden even zeker weten of dit de bedoeling was.
			"""
		ProjectPersonRemovedNotice: (name) -> "#{name} verwijderd."
		ProjectPersonAddedNotice: (name) -> "#{name} toegevoegd."

		KeyboardShortcuts: ->
			'''
				Gebruik simplyHomework als een pro met deze keyboard shortcuts:

				<b>Overzicht</b>: <kbd>go</kbd>
				<b>Agenda</b>: <kbd>ga</kbd>
				<b>Berichten</b>: <kbd>gb</kbd> of <kbd>gm</kbd>
				<b>Instellingen</b>: <kbd>gi</kbd> of <kbd>gs</kbd>
				<b>Zoeken</b>: <kbd>/</kbd>
				<b>Chatbalk zoeken</b>: <kbd>c</kbd>
				<b>Chatten met huidige persoon, vak of project</b>: <kbd>gc</kbd>
				<b>Vorige zijbalk item</b>: <kbd>shift</kbd> + <kbd>pijltje boven</kbd> of <kbd>shift</kbd> + <kbd>k</kbd>
				<b>Volgende zijbalk item</b>: <kbd>shift</kbd> + <kbd>pijltje beneden</kbd> of<kbd>shift</kbd> + <kbd>j</kbd>
			'''
