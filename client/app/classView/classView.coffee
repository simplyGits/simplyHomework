currentClass = -> Router.current().data()
tasksAmount = -> Helpers.getTotal _.reject(GoaledSchedules.find(_homework: { $exists: true }, ownerId: Meteor.userId()).fetch(), (gS) -> !EJSON.equals(gS.classId(), currentClass()._id)), (gS) -> gS.tasksForToday().length

Template.classView.helpers
	currentClass: currentClass
	tasksAmount: tasksAmount
	tasksWord: -> if tasksAmount() is 1 then "taak" else "taken"
	classColor: -> currentClass().__color
	textAlign: -> if Session.get "isPhone" then "left" else "right"

	# recentGrades: ->
	# 	grades = _.filter magisterResult("grades").result, (g) -> g.class().id is currentClass().__classInfo.magisterId
	# 	return _.filter grades, (g) -> new Date(g.dateFilledIn()) > Date.today().addDays(-7) and g.type().type() is 1

	# endGrade: ->
	# 	grades = _.filter magisterResult("grades").result, (g) -> g.class().id is currentClass().__classInfo.magisterId

	# 	endGrade = _.find r, (g) -> g.type().header()?.toLowerCase() is "eind"
	# 	if endGrade.length is 0
	# 		endGrade = _.find r, (g) -> g.type().header()?.toLowerCase() is "e-jr"
	# 	if endGrade.length is 0
	# 		endGrade = _.uniq _.find(r, (g) -> g.type().type() is 2), "_class"

	# 	return endGrade

Template.classView.events
	"mouseenter #classHeader": -> unless Session.get "isPhone" then $("#changeClassIcon").velocity { opacity: 1 }, 100
	"mouseleave #classHeader": -> unless Session.get "isPhone" then $("#changeClassIcon").velocity { opacity: 0 }, 100

	"click #changeClassIcon": ->
		ga "send", "event", "button", "click", "classInfoChange"

		name = if _.contains ["Natuurkunde", "Scheikunde"], (val = currentClass().name) then "Natuur- en scheikunde" else val
		WoordjesLeren.getAllBooks name, (result) ->
			result.pushMore ({name} for name in _.reject Books.find(classId: currentClass()._id).fetch().map((b) -> b.title), (b) -> _.any result, (x) -> x is b)

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

		book = Books.findOne title: bookName
		unless book? or bookName.trim() is ""
			book = New.book bookName, undefined, Session.get("currentSelectedBookDatum")?.id, undefined, _class._id

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