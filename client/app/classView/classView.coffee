bookComputation = null
selectedGradeId = new SReactiveVar Match.Optional Mongo.ObjectID
digitalSchoolUtilities = new ReactiveVar []

bookEngine = new Bloodhound
	name: 'books'
	datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.title
	queryTokenizer: Bloodhound.tokenizers.whitespace
	local: []

classId = -> FlowRouter.getParam 'id'
currentClass = -> Classes.findOne classId()

grades = ->
	Grades.find
		ownerId: Meteor.userId()
		classId: classId()

Template.classView.helpers
	class: -> currentClass()
	classBorderColor: -> chroma(@__color).darken().hex()

	hoursPerWeek: ->
		CalendarItems.find(
			userIds: Meteor.userId()
			classId: classId()
			startDate: $gt: Date.today()
			endDate: $lt: Date.today().addDays 7
		).count()

	gradeGroups: ->
		arr = grades().fetch()
		console.log arr
		_(arr)
			.reject (g) -> g.isEnd
			.uniq (g) -> g.period.id
			.map (g) ->
				name: g.period.name
				grades: (
					_(arr)
						.filter (x) -> x.period.id is g.period.id
						.value()
				)
			.filter (gp) -> gp.grades.length isnt 0
			.value()

	studyUtils: -> StudyUtils.find classId: @_id

	digitalSchoolUtilities: -> digitalSchoolUtilities.get()

	hasGrades: -> grades().count() > 0

	selectedGrade: ->
		Grades.findOne selectedGradeId.get()

	endGrade: ->
		Grades.findOne
			classId: @_id
			ownerId: Meteor.userId()
			isEnd: yes

Template.classView.onCreated ->
	@autorun =>
		id = classId()
		slide id
		@subscribe 'externalStudyUtils', id
		@subscribe 'externalGrades', classId: id

		@subscribe 'classInfo', id, onReady: ->
			c = Classes.findOne id
			if c?
				setPageOptions
					title: c.name
					color: c.__color
			else
				notFound()

	@autorun ->
		unless _.any(grades().fetch(), (g) -> EJSON.equals selectedGradeId.get(), g._id)
			selectedGradeId.set grades().fetch()[0]?._id

Template.classView.events
	"click #changeClassIcon": ->
		analytics?.track 'Open ChangeClassModal', className: @name

		bookComputation = Tracker.autorun =>
			Meteor.subscribe 'scholieren.com'
			Meteor.subscribe 'books', @_id

			books = Books.find(classId: @_id).fetch()

			scholierenClass =
				ScholierenClasses.findOne
					id: currentClass().__classInfo.scholierenId
			books = books.concat _.reject scholierenClass?.books, (b) -> _.contains _.pluck(books, 'title'), b.title

			bookEngine.clear()
			bookEngine.add books

		showModal 'changeClassModal', {
			onHide: -> bookComputation.stop(); console.log 'stopping comp..'
		}, currentClass

Template.changeClassModal.onRendered ->
	bookEngine.initialize()

	$('#changeBookInput').typeahead(null,
		source: bookEngine.ttAdapter()
		displayKey: 'title'
	).on 'typeahead:selected', (obj, datum) -> Session.set 'currentSelectedBookDatum', datum

Template.changeClassModal.events
	'click #goButton': ->
		bookName = $('#changeBookInput').val()

		book = Books.findOne title: bookName
		unless book? or bookName.trim() is ''
			book = new book bookName, undefined, val.id, undefined, c._id
			Books.insert book

		Meteor.users.update Meteor.userId(), $pull: classInfos: id: @_id
		Meteor.users.update Meteor.userId(), $push: classInfos:
			_.extend @__classInfo, bookId: book?._id

		analytics?.track 'Class Info Changed', className: @name
		$('#changeClassModal').modal 'hide'

	'click #hideClassButton': ->
		$('#changeClassModal').modal 'hide'
		alertModal(
			'Zeker weten?',
			'''
				Als je dit vak verbergt kan je het niet meer zien in de zijbalk, je kan
				het vak weer toonbaar maken in instellingen > vakken.
			''',
			DialogButtons.OkCancel,
			{ main: 'Verbergen', second: 'Toch niet' },
			{ main: 'btn-danger' },
			main: =>
				FlowRouter.go 'overview'
				Meteor.users.update Meteor.userId(), $pull: classInfos: id: @_id
				Meteor.users.update Meteor.userId(), $push: classInfos:
					_.extend @__classInfo, hidden: yes
			second: ->
		)

Template.gradeRow.events "click .gradeRow": -> selectedGradeId.set @_id

Template.gradeRow.helpers selected: -> if selectedGradeId.get() is @_id then "selected" else ""
