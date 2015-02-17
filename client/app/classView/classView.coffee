bookSub = null

grades = new ReactiveVar []
loadingGrades = new ReactiveVar yes
selectedGrade = new ReactiveVar null

studyGuides = new ReactiveVar []
digitalSchoolUtilities = new ReactiveVar []

currentClass = -> Router.current().data()
tasksAmount = -> Helpers.getTotal _.reject(GoaledSchedules.find(_homework: { $exists: true }, ownerId: Meteor.userId()).fetch(), (gS) -> !EJSON.equals(gS.classId(), currentClass()._id)), (gS) -> gS.tasksForToday().length

###*
# Converts a grade to a number, can be Dutch grade style or English. More can be added.
# If the `grade` can't be converted it will return NaN.
#
# @method gradeConverter
# @param grade {String} The grade to convert.
# @return {Number} `grade` converted to a number. Defaults to NaN.
###
gradeConverter = (grade) ->
	# Normal dutch grades
	val = grade.replace(",", ".").replace(/[^\d\.]/g, "")
	unless val.length is 0 or _.isNaN(+val)
		return val

	# English grades
	englishGradeMap =
		"F": 1.7
		"E": 3.3
		"D": 5.0
		"C": 6.7
		"B": 8.3
		"A": 10.0

	if _(englishGradeMap).keys().contains(grade.toUpperCase())
		return englishGradeMap[grade.toUpperCase()]

	return NaN

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
	digitalSchoolUtilities: -> digitalSchoolUtilities.get()

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

	@autorun (c) ->
		grades.set(_(fetchedGrades.get())
			.filter((g) -> g.class().id() is currentClass().__classInfo.magisterId and g.grade()?)
			.forEach((g) -> g.__insufficient = if gradeConverter(g.grade()) < 5.5 then "insufficient" else "")
			.value()
		)

		Tracker.nonreactive ->
			p = _helpers.asyncResultWaiter grades.get().length, -> grades.dep.changed()
			for grade in grades.get() when not grade._filled
				grade.fillGrade p

	@autorun -> studyGuides.set _.filter fetchedStudyGuides.get(), (s) -> s.class()? and s.class().id() is currentClass().__classInfo.magisterId
	@autorun ->
		Meteor.subscribe "magisterDigitalSchoolUtilties", currentClass().__classInfo.magisterDescription
		digitalSchoolUtilities.set MagisterDigitalSchoolUtilties.find(
			_class: $exists: yes
			"_class._description": currentClass().__classInfo.magisterDescription
		).fetch()

Template.classView.events
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
