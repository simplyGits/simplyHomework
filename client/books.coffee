initted = no
@BooksHandler =
	engine: new Bloodhound
		name: 'books'
		datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.title
		queryTokenizer: Bloodhound.tokenizers.whitespace
		local: []

	init: ->
		unless initted
			@engine.initialize()
			initted = yes

	run: (c) ->
		@init()

		Meteor.subscribe 'books', c._id

		books = _(getAvailableBooks c._id)
			.concat Books.find(classId: c._id).fetch()
			.uniq 'title'
			.value()

		@engine.clear()
		@engine.add books
		books
