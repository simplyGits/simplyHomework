root = @

###*
# Repesents a school.
#
# @class School
###
class @School
	###*
	# Constructor for the current School
	#
	# @method constructor
	# @param _parent {Object} The creator of this object.
	# @param _name {String} The name of the school
	# @param _url {String} The URL of the school.
	# @param _location {Location} The location of the school
	###
	constructor: (@_parent, @_name, @_url, @_location) ->
		@_className = "School"
		@_id = new Meteor.Collection.ObjectID()

		@_books = []   # books by ID
		@_classes = [] # classes by ID
		@_users = []   # users by ID.
		@_utils = []   # utils by ID.

		@dependency = new Deps.Dependency

		@name = root.getset "_name", String
		@url = root.getset "_url", String
		@location = root.getset "_location", Match.Where root.Location._match

	_setDeps: ->
		Deps.autorun (computation) => # Calls the dependency of the sender object, unless it's null
			@dependency.depend()
			@_parent.dependency.changed() if @_parent? and !computation.firstRun

	@_match: (school) ->
		return Match.test school, Match.ObjectIncluding
				_name: String
				_url : String
				_location: Location._match

	###*
	# Return a cursor pointing to the books that this school uses.
	#
	# @method books
	# @return {Cursor} Cursor pointing to the books this school uses.
	###
	books: () -> return root.Books.find { _id: { $in: @_books }}
	###*
	# Adds a new book to the collection of this school and the public books collection if it doesn't exist yet.
	#
	# @method addBook
	# @param book {Book} The book to add
	###
	addBook: (book) ->
		Books.insert(book) if Books.find(book).count() is 0
		@_books.push book._id
		@dependency.changed()

	###*
	# Removes the book from the current school. By removing it's ID from the _books array.
	#
	# @method removeBook
	# @param book {Book} The book to remove.
	###
	removeBook: (book) ->
		@_books = _.without @_books, book._id
		@dependency.changed()

	###*
	# Return a cursor pointing to the classes that this school offers.
	#
	# @method classes
	# @return {Cursor} A cursor pointing to the classes this school offers.
	###
	classes: -> return Root.classes.find { _id: { $in: @_classes }}

	###*
	# Adds a new class to the collection of this school and the public classes collection if it doesn't exist yet.
	#
	# @method addClass
	# @param _class {Class} The class to add.
	###
	addClass: (_class) ->
		_class._parent = @
		@_classes.push _class._id
		@dependency.changed()

	###*
	# Removes the class from the current school. By removing it's ID from the classes array.
	#
	# @method removeClass
	# @param _class {Class} The class to remove.
	###
	removeClass: (_class) ->
		_class._parent = null
		@_classes = _.without @_classes, _class._id
		@dependency.changed()

	###*
	# Return a cursor pointing to the users that that are pupils of this school.
	#
	# @method users
	# @return {Cursor} A cursor pointing to the users that are pupils of this school.
	###
	users: -> return Meteor.users.find { _id: { $in: @_users }}

	###*
	# Adds an user to the collection of this school.
	#
	# @method addClass
	# @param userId {Number} The ID of the user to add.
	###
	addUser: (userId) ->
		@_users.push userId
		@dependency.changed()

	###*
	# Removes an user from the collection of this school.
	#
	# @method removeUser
	# @param userId {Number} The ID of the user to remove.
	###
	removeUser: (userId) ->
		@_users = _.without @_users, userId
		@dependency.changed()

	utils: -> return root.Utils.find { _id: { $in: @_utils }}

	addUtil: (util) ->
		if util.binding?
			util.binding.bind

	timeToGetThere: (@currentLocation) ->
		# use Google Maps to get the shizzle
