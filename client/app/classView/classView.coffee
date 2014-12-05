currentClass = -> Router.current().data()
tasksAmount = -> Helpers.getTotal _.reject(GoaledSchedules.find(_homework: { $exists: true }, ownerId: Meteor.userId()).fetch(), (gS) -> !EJSON.equals(gS.classId(), currentClass()._id)), (gS) -> gS.tasksForToday().length

Template.classView.helpers
	currentClass: currentClass
	tasksAmount: tasksAmount
	tasksWord: -> if tasksAmount() is 1 then "taak" else "taken"
	classColor: -> currentClass().__color
	textAlign: -> if Session.get "isPhone" then "left" else "right"

Template.classView.events
	"mouseenter #classHeader": -> unless Session.get "isPhone" then $("#changeClassIcon").velocity { opacity: 1 }, 100
	"mouseleave #classHeader": -> unless Session.get "isPhone" then $("#changeClassIcon").velocity { opacity: 0 }, 100

	"click #changeClassIcon": ->
		ga "send", "event", "button", "click", "classInfoChange"

		name = if _.contains ["Natuurkunde", "Scheikunde"], (val = currentClass().name()) then "Natuur- en scheikunde" else val
		WoordjesLeren.getAllBooks name, (result) ->
			result.pushMore ({name} for name in _.reject currentClass().books().map((b) -> b.title()), (b) -> _.any result, (x) -> x is b)

			bookEngine.clear()
			bookEngine.add result

		$("#changeColorInput").colorpicker "destroy"
		$("#changeColorInput").colorpicker color: currentClass().__color
		$("#changeColorLabel").css color: currentClass().__color

		$("#changeClassModal").modal backdrop: false

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
		unless book?
			book = new Book _class, bookName, undefined, Session.get("currentSelectedBookDatum").id, undefined
			Classes.update _class._id, $push: { _books: book }

		Meteor.users.update Meteor.userId(), { $pull: { classInfos: { id: _class._id }}}
		Meteor.users.update Meteor.userId(), { $push: { classInfos: { id: _class._id, color, bookId: book._id }}}

		$("meta[name='theme-color']").attr "content", color
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
				Router.go "app"
				Meteor.users.update Meteor.userId(), { $pull: { classInfos: { id: currentClass()._id }}}
			second: -> return
		)