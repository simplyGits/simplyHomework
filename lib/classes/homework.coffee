root = @

@HomeworkType =
	"Unknown"     : 0
	"Normal"      : 1
	"Test"        : 2
	"Exam"        : 3
	"Quiz"        : 4
	"OralTest"    : 5
	"Information" : 6

###*
# Class for a homework item. Extends from the ScheduleItem class.
#
# @class Homework
###
class @Homework
	constructor: (@_parent, @_description, @_dueDate, @_classId, @_homeworkType, @_addedManually, @_isPublic) ->
		@_className = "Homework"

		@dependency = new Deps.Dependency
		@description = root.getset "_description", String
		@dueDate = root.getset "_dueDate", Date
		@classId = root.getset "_classId", String
		@homeworkType = root.getset "_homeworkType", Number
		@addedManually = root.getset "_addedManually", Boolean
		@ispublic = root.getset "_isPublic", Boolean
		@weigth = root.getset "_weigth", (w) => _.contains [2..5], @homeworkType() and Match.test w, Number
		@__parsedData = root.getset "_parsedData"
		
	_setDeps: ->
		Deps.autorun (computation) => # Calls the dependency of the sender object, unless it's null
			@dependency.depend()
			@_parent.dependency.changed() if @_parent? and !computation.firstRun

	@_match: (homework) ->
		return Match.test homework, Match.ObjectIncluding
				_description   : String
				_dueDate       : Date
				_classId       : String
				_homeworkType  : Number
				_book		   : root.Book._match
				_addedManually : Boolean
				_isPublic      : Boolean
				_weigth        : Number

	###*
	# Parses the current HomeworkInstance. Or, if it's already parsed, returns the cached parsed ParsedData instance.
	#
	# @method parsedHomework
	# @return {ParsedData} The data parsed as a ParsedData instance.
	###
	parsedHomework: -> return @__parsedData() ? (@__parsedData Parser.parseHomework @)

	getParsedParagraphs: (book) ->
		paras = []
		for paragraphData in @parsedHomework().paragraphData
			for chapter in _.filter(book.chapters(), (c) -> _.contains(paragraphData.parentChapter.values, c.number()))
				for para in _.filter(chapter.paragraphs(), (p) -> _.contains(paragraphData.values, p.number()))
					paras.push para
		return paras

	###*
	# Checks if the given item is a valid Homework item.
	#
	# @method isValidHomework
	# @param object {Object} The object to test.
	###
	@isValidHomework: (object) -> return root.Homework._match object

	###*
	# Checks if the given array is a valid homework array.
	#
	# @method isValidHomeworkArray
	# @param array {Array} The array to check.
	# @return {Boolean} Whether the given array is a valid Homework array.
	###
	@isValidHomeworkArray: (array) -> return Match.test array, [root.Homework._match]

	class: -> Classes.findOne @classId()