Template.forgotPass.events
	"keydown": (event) ->
		mail = event.target.value.toLowerCase()
		if event.which isnt 13
			$("#forgotPassMailInput").tooltip "destroy"
			return

		Meteor.call "mailExists", mail, (err, result) ->
			if result
				swalert title: "Mail verstuurd", text: "Je krijgt zometeen een mailtje waarmee je je wachtwoord kan veranderen.", type: "success"
				Accounts.forgotPassword(email: mail)
			else if !result
				$("#forgotPassMailInput").addClass("has-error").tooltip(placement: "bottom", title: "Geen account met deze e-mail gevonden").tooltip("show")
			else
				Meteor.call("log", "log", "Error while checking mail. #{err.message}")
				swalert title: "Fout", text: "Onbekende fout, we zijn op de hoogte gesteld", type: "error"

Template.resetPass.events
	"keydown": ->
		return if event.which isnt 13

		Accounts.resetPassword Router.current().params.token, event.target.value, (err) ->
			if err?
				if err.reason is "Token expired"
					swalert title: "Reeds gebruikt", html: 'Wachtwoord is al veranderd met deze link. Klik <a href="/forgot">hier</a> als je je wachtwoord nog een keer wilt wijzingen.', type: "error"
				else
					Meteor.call("log", "log", "Error while resetting password. #{err.message}")
					swalert title: "Fout", text: "Onbekende fout, we zijn op de hoogte gesteld", type: "error"
			else
				Router.go "app"
				swalert title: "yay", text: "Wachtwoord is aangepast. Denk ik... Naja, laten we zeggen van wel.", type: "success"

Template.resetPass.rendered = -> $("#hintText").velocity { opacity: 1 }, 15000