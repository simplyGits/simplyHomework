Template.admin.events
	"keydown": (event) ->
		$(event.target).val amplify.store("lastCommand") if event.which is 38 and amplify.store("lastCommand")?

		return if event.which isnt 13

		val = event.target.value.trim()
		event.target.value = ""

		useCoffee = val[0] isnt "#"
		val = val[1..] unless useCoffee
		NProgress.start()

		Meteor.call "execute", val, useCoffee, (error, result) ->
			amplify.store "lastCommand", val
			NProgress.done()
			if error? then $(".commandOutput").html '<span style="color: red">' + "<h3>#{error.message}</h3>" + error.stack.replace(/\n|\r/ig, "<br><br>") + '</a><br><br>'
			else $(".commandOutput").JSONView result

Template.admin.rendered = ->
	unless userIsInRole()
		swalert title: "D:", text: "Hoe ben je hier beland? Je hoort hier niet eens te kunnen komen", confirmButtonText: "Terug", type: "error", onSuccess: -> Router.go "launchPage"

	$("input").focus()