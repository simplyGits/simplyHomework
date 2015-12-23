Template.clean.helpers
	i18nId: ->
		hour = new Date().getHour()

		return "guiderGreeting_" + (
			if 0 < hour < 6 then "night"
			if 6 < hour < 12 then "morning"
			if 12 < hour < 18 then "afternoon"
			if 18 < hour < 0 then "evening"
		)
