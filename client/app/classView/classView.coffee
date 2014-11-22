currentClass = -> Router.current().data()
tasksAmount = -> Helpers.getTotal _.reject(GoaledSchedules.find(_homework: { $exists: true }, ownerId: Meteor.userId()).fetch(), (gS) -> !EJSON.equals(gS.classId(), currentClass()._id)), (gS) -> gS.tasksForToday().length

Template.classView.helpers
	currentClass: currentClass
	tasksAmount: tasksAmount
	tasksWord: -> if tasksAmount() is 1 then "taak" else "taken"
	classColor: -> currentClass().__color
	textAlign: -> if Session.get "isPhone" then "left" else "right"

Template.classView.events
	"mouseenter #classHeader": -> unless Session.get "isPhone" then $("#classNameChangeIcon").velocity { opacity: 1 }, 100
	"mouseleave #classHeader": -> unless Session.get "isPhone" then $("#classNameChangeIcon").velocity { opacity: 0 }, 100

	"click #classNameChangeIcon": ->
		ga "send", "event", "button", "click", "classNameChange"

		name = if _.contains ["Natuurkunde", "Scheikunde"], (val = currentClass().name()) then "Natuur- en scheikunde" else val
		WoordjesLeren.getAllBooks name, (result) ->
			bookEngine.clear()
			bookEngine.add result

		$("#changeColorInput").colorpicker "destroy"
		$("#changeColorInput").colorpicker color: currentClass().__color
		$("#changeColorLabel").css color: currentClass().__color

		$("#changeClassModal").modal()
		# Because our modal is inside the content div the backdrop also blocks the modal. Force remove it.
		$(".modal-backdrop").css zIndex: -1

Template.changeClassModal.rendered = ->
	$("#changeColorInput").colorpicker color: currentClass().__color
	$("#changeColorInput").on "changeColor", -> $("#changeColorLabel").css color: $("#changeColorInput").val()
	bookEngine.initialize()

	$("#changeBookInput").typeahead(null,
		source: bookEngine.ttAdapter()
		displayKey: "name"
	).on "typeahead:selected", (obj, datum) -> Session.set "currentSelectedBookDatum", datum

Template.changeClassModal.events
	"click #goButton": ->
		_class = currentClass()

		color = $("#changeColorInput").val()
		bookName = $("#changeBookInput").val()

		book = _class.books().smartFind bookName, (b) -> b.title()
		book ?= _class.addBook bookName, undefined, Session.get("currentSelectedBookDatum").id, undefined

		Meteor.users.update Meteor.userId(), { $pull: { classInfos: { id: _class._id }}}
		Meteor.users.update Meteor.userId(), { $push: { classInfos: { id: _class._id, color, bookId: book._id }}}

		$("#changeClassModal").modal "hide"

	"click #deleteClassButton": ->
		$("#changeClassModal").modal "hide"
		alertModal(
			"Zeker weten?",
			"Als je dit vak verwijderd kunnen alle gegevens, zoals projecten verwijderd worden.\nDit gebeurd wanneer iedereen van het project dit vak verwijderd heeft.\nDit kan niet ongedaan worden gemaakt.",
			DialogButtons.OkCancel,
			{ main: "Verwijderen", second: "Toch niet" },
			{ main: "btn-danger" },
			main: ->
				Meteor.users.update Meteor.userId(), { $pull: { classInfos: { id: currentClass()._id }}}
				Router.go "app"
			second: -> return
		)