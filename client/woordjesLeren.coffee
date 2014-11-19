urls =
	categories: "http://www.corsproxy.com/www.woordjesleren.nl/api/select_categories.php"
	books: "http://www.corsproxy.com/www.woordjesleren.nl/api/select_books.php?category="
	lists: "http://www.corsproxy.com/www.woordjesleren.nl/api/select_lists.php?book="

categories = []

class @WoordjesLeren
	@getAllClasses: (callback) ->
		if categories.length isnt 0
			callback categories
		else
			$.get urls.categories, (result) ->
				callback categories = n.data.trim() for n in $(result).find("category").contents()

	@getAllBooks: (className, callback) ->
		$.get urls.categories, (result) ->
			classId = $(result).find("category:contains('#{className}')").attr("id")
			$.get urls.books + classId, (result) ->
				callback ({ id: Number(n.attributes.id.value), name: n.innerHTML.trim() } for n in $(result).find("book"))

	@getAllLists: (className, bookName, callback) ->
		$.get urls.categories, (result) ->
			classId = $(result).find("category:contains('#{className}')").attr("id")
			$.get urls.books + classId, (result) ->
				bookId = $(result).find("book:contains('#{bookName}')").attr("id")
				$.get urls.lists + bookId, (result) ->
					callback ({ id: Number(n.attributes.id.value), name: n.innerHTML } for n in $(result).find("list"))