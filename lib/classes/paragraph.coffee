root = @

class @Understanding
	@understandingEnum:
		Perfect: 1
		Much: 2
		Better: 3
		Sufficient: 4
		Insufficient: 5
		Little: 6

	@understandingEnumMatch: (s) -> _.contains _.values(root.Understanding.understandingEnum), s

	constructor: (@_parent, @_voterId, @_understanding) ->
		@_className = "Understanding"
		@_id = new Meteor.Collection.ObjectID()

		@dependency = new Deps.Dependency

		@voterId = root.getset "_voterId", String
		@understanding = root.getset "_understanding", root.Understanding.understandingEnumMatch

	_setDeps: ->
		Deps.autorun (computation) => # Calls the dependency of the sender object, unless it's null
			@dependency.depend()
			@_parent.dependency.changed() if @_parent? and !computation.firstRun

	@_match: (understanding) ->
		return Match.test understanding, Match.ObjectIncluding
				_voterId: String
				_understanding: root.Understanding.understandingEnumMatch

class @Paragraph
	# The schedular looks at the difficulty to calculate the quantity of the paragraphs to do per day.
	@difficultyEnum:
		Unknown : 0
		Small   : 1
		Medium  : 2
		Large   : 3

	@difficultyEnumMatch: (s) -> _.contains _.values(root.Paragraph.difficultyEnum), s

	constructor: (@_parent, @_name, @_number, @_difficulty, @_isVocabulary = no) ->
		@_className = "Paragraph"
		@_id = new Meteor.Collection.ObjectID()

		@_exercises = []
		@_understandings = []

		@name = root.getset "_name", String
		@difficulty = root.getset "_difficulty", root.Paragraph.difficultyEnumMatch, yes, null, (d) -> if d is 0 then 2 else d
		@number = root.getset "_number", Number
		@understandings = root.getset "_understandings", [root.Understanding._match], no
		@isVocabulary = root.getset "_isVocabulary", Boolean

	###*
	# Returns the utils for this Paragraph from the parent book.
	#
	# @method utils
	# @return {Cursor} Cursor pointing to the utils for this Paragraph from the parent book
	###
	utils: -> return root.Utils.find { paragraphId: @_id }

	addUtil: (util) ->
		if !util.binding?
			util.binding.bindParagraph @
		else
			util.binding = new Binding @, @_book, [@_parent], @

	removeUtil: (util, removeFromBook) ->
		util.binding.unbindParagraph @
		util.binding.unbindChapter(@_parent) if removeFromBook

	getUnderstanding: (userId) -> return _.find @understandings(), (u) -> EJSON.equals u.voterId(), userId

	calculatePriority: (goaledSchedule) ->
		avgOtherClasses = root.Helpers.getAverage(_.reject(root.Schools.findOne(Meteor.users.findOne(goaledSchedule.ownerId).schoolId).classes(), (c) => c._id is @classId()), (c) -> c.getGradeAverage(userId))
		avgCompared = Math.round 100 - ((@class().getGradeAverage(goaledSchedule.ownerId) / avgOtherClasses) * 100)

		someClassesInsufficient = _.some(_.reject(root.Schools.findOne(Meteor.users.findOne(goaledSchedule.ownerId).schoolId).classes(), (c) -> EJSON.equals(c._id, @classId())), (c) -> c.getGradeAverage(userId) < 5.5)

		exceptionCase = switch
			when @class().getGradeAverage(goaledSchedule.ownerId) < 5.5 then 1
			when someClassesInsufficient then 2
			else 0

		exceptionPoints = switch
			when exceptionCase is 0 # get average with one point extra
				newAverage = if goaledSchedule.class().getGradeAverage() >= 9.5 then 10 else Math.ceil(@class().getGradeAverage() - .4) + .5
				neededGrade = ((newAverage * goaledSchedule.homework().weigth()) + (newAverage * goaledSchedule.class().getGradeWeigthSum()) - @class().getGradeAverage()) / @homework().weigth()
				switch
					when neededGrade is 1 then 1
					when _.contains [2..3], neededGrade then 2
					when _.contains [4..5], neededGrade then 3
					when _.contains [6..7], neededGrade then 4
					when _.contains [8..9], neededGrade then 5
					when neededGrade >= 10 then 6
			when exceptionCase is 1 # get average to 5.5
				neededGrade = ((5.5 * @homework().weigth()) + (5.5 * @class().getGradeWeigthSum()) - @class().getGradeAverage()) / @homework().weigth()
				switch
					when neededGrade is 1 then 1
					when neededGrade is 2 then 2
					when _.contains [3..4], neededGrade then 3
					when _.contains [5..6], neededGrade then 4
					when _.contains [7..8], neededGrade then 5
					when neededGrade >= 9 then 6
			else # stay same grade
				neededGrade = ((@class().getGradeAverage() * @homework().weigth()) + (@class().getGradeAverage() * @class().getGradeWeigthSum()) - @class().getGradeAverage()) / @homework().weigth()
				switch
					when neededGrade is 1 then 1
					when _.contains [2..3], neededGrade then 2
					when _.contains [4..5], neededGrade then 3
					when neededGrade is 6 then 4
					when _.contains [7..9], neededGrade then 5
					when neededGrade >= 10 then 6

		avgPoints = switch
			when _.contains  [1..12], avgCompared then 1
			when _.contains [13..18], avgCompared then 2
			when _.contains [19..30], avgCompared then 3
			when _.contains [31..42], avgCompared then 4
			when _.contains [43..59], avgCompared then 5
			when _.contains [60..90], avgCompared then 6

		return avgPoints + @getUnderstanding(goaledSchedule.ownerId).understanding() + @difficulty() + exceptionPoints

	chapter: -> @_parent
	book: -> @_parent._parent
