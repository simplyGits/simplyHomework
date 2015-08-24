bookComputation = null
selectedGradeId = new SReactiveVar Match.Optional Mongo.ObjectID
digitalSchoolUtilities = new ReactiveVar []
currentClass = -> Router.current().data()

bookEngine = new Bloodhound
	name: 'books'
	datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.title
	queryTokenizer: Bloodhound.tokenizers.whitespace
	local: []

grades = (options) ->
	StoredGrades.find {
		ownerId: Meteor.userId()
		classId: currentClass()._id
	}, options

Template.classView.helpers
	tasksAmount: -> @__taskAmount
	tasksWord: -> if @__taskAmount is 1 then 'taak' else 'taken'
	classColor: -> @__color()
	textAlign: -> if Session.get 'isPhone' then 'left' else 'right'

	gradeGroups: ->
		arr = StoredGrades.find(
			classId: @_id
			ownerId: Meteor.userId()
			isEnd: no
		).fetch()

		_(arr)
			.uniq (g) -> g.period.id
			.map (g) ->
				name: g.period.name
				grades: (
					_(arr)
						.filter (x) -> x.period.id is g.period.id
						.map (g) -> _.extend g, {
							__insufficient: if g.passed then '' else 'insufficient'
							grade: g.toString()
						}
						.value()
				)
			.filter (gp) -> gp.grades.length isnt 0
			.value()

	studyUtils: -> StudyUtils.find classId: @_id

	digitalSchoolUtilities: -> digitalSchoolUtilities.get()

	hasGrades: -> grades().count() > 0

	selectedGrade: -> StoredGrades.findOne selectedGradeId.get()

	endGrade: ->
		StoredGrades.findOne
			classId: @_id
			ownerId: Meteor.userId()
			isEnd: yes

Template.classView.onRendered ->
	fetchedGrades = new ReactiveVar []
	@subscribe 'externalGrades'
	@subscribe 'externalStudyUtils', Blaze.getData()._id

	@autorun ->
		unless _.contains grades().fetch(), selectedGradeId.get()
			selectedGradeId.set grades(limit: 1).fetch()[0]?._id

	###
	@autorun ->
		Meteor.subscribe "magisterDigitalSchoolUtilties", currentClass().__classInfo().magisterDescription
		digitalSchoolUtilities.set MagisterDigitalSchoolUtilties.find(
			_class: $exists: yes
			"_class._description": currentClass().__classInfo().magisterDescription
		).fetch()
	###

Template.classView.events
	"click #changeClassIcon": ->
		ga "send", "event", "button", "click", "classInfoChange"

		bookComputation = Tracker.autorun ->
			Meteor.subscribe 'scholieren.com'
			Meteor.subscribe 'books', @_id

			books = Books.find(classId: @_id).fetch()

			scholierenClass = ScholierenClasses.findOne id: @__classInfo().scholierenId
			books.pushMore _.filter scholierenClass?.books, (b) -> not _.contains (x.title for x in books), b.title

			bookEngine.clear()
			bookEngine.add books

		showModal 'changeClassModal', {
			onHide: -> bookComputation.stop(); console.log 'stopping comp..'
		}, currentClass

		$("#changeColorInput").colorpicker color: @__color()
		$("#changeColorLabel").css color: @__color()

Template.changeClassModal.onRendered ->
	$('#changeColorInput')
		.colorpicker color: @currentData().__color()
		.on 'changeColor', -> $('#changeColorLabel').css color: $('#changeColorInput').val()
	bookEngine.initialize()

	$('#changeBookInput').typeahead(null,
		source: bookEngine.ttAdapter()
		displayKey: 'title'
	).on 'typeahead:selected', (obj, datum) -> Session.set 'currentSelectedBookDatum', datum

Template.changeClassModal.events
	'click #goButton': ->
		color = $('#changeColorInput').val()
		bookName = $('#changeBookInput').val()

		book = Books.findOne title: bookName
		unless book? or bookName.trim() is ''
			book = new book bookName, undefined, val.id, undefined, c._id
			Books.insert book

		Meteor.users.update Meteor.userId(), $pull: classInfos: id: @_id
		Meteor.users.update Meteor.userId(), $push: classInfos:
			id: @_id
			color: color
			bookId: book._id

		setPageOptions { color }
		$('#changeClassModal').modal 'hide'

	"click #deleteClassButton": ->
		$("#changeClassModal").modal "hide"
		alertModal(
			'Zeker weten?',
			'''
				Als je dit vak verwijdert kunnen alle gegevens, zoals projecten verwijdert worden.
				Dit kan niet ongedaan worden gemaakt
				Projecten worden alleen verwijderd wanneer alle deelnemers van het project dit vak verwijderd hebben.
			''',
			DialogButtons.OkCancel,
			{ main: 'Verwijderen', second: 'Toch niet' },
			{ main: 'btn-danger' },
			main: ->
				Router.go 'app'
				Meteor.users.update Meteor.userId(), $pull: classInfos:
					id: @._id
			second: ->
		)

Template.gradeRow.events "click .gradeRow": -> selectedGradeId.set @_id

Template.gradeRow.helpers selected: -> if selectedGradeId.get() is @_id then "selected" else ""
