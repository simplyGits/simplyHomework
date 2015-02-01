bookSub = null

grades = new ReactiveVar []
loadingGrades = new ReactiveVar yes
selectedGrade = new ReactiveVar null

studyGuides = new ReactiveVar []
loadingStudyGuides = new ReactiveVar yes

currentClass = -> Router.current().data()
tasksAmount = -> Helpers.getTotal _.reject(GoaledSchedules.find(_homework: { $exists: true }, ownerId: Meteor.userId()).fetch(), (gS) -> !EJSON.equals(gS.classId(), currentClass()._id)), (gS) -> gS.tasksForToday().length

Template.classView.helpers
	currentClass: currentClass
	tasksAmount: -> currentClass().__taskAmount
	tasksWord: -> if tasksAmount() is 1 then "taak" else "taken"
	classColor: -> currentClass().__color
	textAlign: -> if Session.get "isPhone" then "left" else "right"

	gradeGroups: ->
		return _(grades.get())
			.uniq (g) -> g.gradePeriod().name()
			.reject (g) -> g.type().type() is 2 or g.type().type() is 4
			.map (g) ->
				name: g.gradePeriod().name()
				grades: _.filter grades.get(), (x) -> x.gradePeriod().name() is g.gradePeriod().name() and x.type().type() isnt 2
			.filter (gp) -> gp.grades.length isnt 0
			.value()
	studyGuides: -> studyGuides.get()

	loadingGrades: -> loadingGrades.get()
	loadingStudyGuides: -> loadingStudyGuides.get()
	hasGrades: -> grades.get().length > 0

	selectedGrade: -> selectedGrade.get()

	endGrade: ->
		endGrade  = _.find grades.get(), (g) -> g.type().header()?.toLowerCase() is "e-jr"
		endGrade ?= _.find grades.get(), (g) -> g.type().header()?.toLowerCase() is "eind"
		endGrade ?= _.find grades.get(), (g) -> g.type().type() is 2

		return endGrade

Template.classView.rendered = ->
	fetchedGrades = new ReactiveVar []
	fetchedStudyGuides = new ReactiveVar []

	magisterResult "grades", (e, r) ->
		return unless Router.current().route.getName() is "classView"
		fetchedGrades.set r ? []
		loadingGrades.set no

	magisterResult "studyGuides", (e, r) ->
		return unless Router.current().route.getName() is "classView"
		fetchedStudyGuides.set r ? []
		loadingStudyGuides.set no

	@autorun ->
		return if _.contains(grades.get(), selectedGrade.get())
		selectedGrade.set grades.get()[0]

	@autorun ->
		grades.set(_(fetchedGrades.get())
			.filter((g) -> g.class().id() is currentClass().__classInfo.magisterId and g.grade()?)
			.forEach((g) -> g.__insufficient = if +g.grade().replace(",", ".").replace(/[^\d\.]/g, "") < 5.5 then "insufficient" else "")
			.value()
		)

	@autorun -> studyGuides.set _.filter fetchedStudyGuides.get(), (s) -> s.class()? and s.class().id() is currentClass().__classInfo.magisterId

Template.classView.events
	"mouseenter #classHeader": -> unless Session.get "isPhone" then $("#changeClassIcon").velocity { opacity: 1 }, 100
	"mouseleave #classHeader": -> unless Session.get "isPhone" then $("#changeClassIcon").velocity { opacity: 0 }, 100

	"click #changeClassIcon": ->
		ga "send", "event", "button", "click", "classInfoChange"
		bookSub = Meteor.subscribe "books", new Meteor.Collection.ObjectID(@params.classId), ->
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
		bookSub.stop()

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

Template.gradeRow.events "click .gradeRow": -> selectedGrade.set @

Template.gradeRow.helpers selected: -> if selectedGrade.get() is @ then "selected" else ""
