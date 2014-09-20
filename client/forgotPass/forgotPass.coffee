Template.forgotPass.events
	"keydown": (event) ->
		mail = event.target.value.toLowerCase()
		if event.which isnt 13
			$("#forgotPassMailInput").tooltip "destroy"
			return

		Meteor.call "mailExists", mail, (err, result) ->
			if result
				alertModal("Mail verstuurd", "Je krijgt zometeen een mailtje waarmee je je wachtwoord kan veranderen.")
				Accounts.forgotPassword(email: mail)
			else if !result
				$("#forgotPassMailInput").addClass("has-error").tooltip(placement: "bottom", title: "Geen account met deze e-mail gevonden").tooltip("show")
			else
				Meteor.call("log", "log", "Error while checking mail. #{err.message}")
				alertModal("Fout", "Onbekende fout, we zijn op de hoogte gesteld")

Template.resetPass.events
	"keydown": ->
		return if event.which isnt 13

		Accounts.resetPassword Router.current().params.token, event.target.value, (err) ->
			if err?
				if err.reason is "Token expired"
					alertModal "Reeds gebruikt", 'Wachtwoord is al veranderd met deze link. Klik <a href="/forgot">hier</a> als je je wachtwoord nog een keer wilt wijzingen.'
				else
					Meteor.call("log", "log", "Error while checking mail. #{err.message}")
					alertModal("Fout", "Onbekende fout, we zijn op de hoogte gesteld")
			else
				Router.go "app"
				alertModal "yay", "Wachtwoord is aangepast. Denk ik... Naja, laten we zeggen van wel."

Template.resetPass.rendered = -> $("#hintText").velocity { opacity: 1 }, 15000