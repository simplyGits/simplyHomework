@BooksHandler =
	engine: new Bloodhound
		name: 'books'
		datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.title
		queryTokenizer: Bloodhound.tokenizers.whitespace
		local: []

	run: (c) ->
		@engine.initialize() # TODO: make this only run once.

		# TODO: search on basis of scholierenId stored on SchoolClass object.

		Meteor.subscribe 'books', c._id

		classes = getAvailableClasses()
		externalClass = _.find classes, (x) ->
			a = Helpers.contains c.name, x.name, yes
			b = Helpers.contains x.name, c.name, yes
			a or b

		books = _(externalClass?.books)
			.concat Books.find(classId: c._id).fetch()
			.uniq 'title'
			.value()

		@engine.clear()
		@engine.add books
		books
