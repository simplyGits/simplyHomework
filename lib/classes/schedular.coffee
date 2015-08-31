root = this

###*
# Calculates the difficulty for the given `paragraph` in relation
# with the given `goaledSchedule` and `grades`.
# @method calculateParagraphPriority
# @param paragraph {Paragraph} The paragraph to calculate the priorty for.
# @param goaledSchedule {GoaledSchedule} The GoaledSchedule to use for calculating the priorty.
# @param grades {Grade[]} Array of FILLED grades to use for calculating out the priority.
# @return {Number} The priorty of the paragraph.
###
@calculateParagraphPriority = (goaledSchedule, paragraph, grades) ->
	user = Meteor.users.findOne goaledSchedule.ownerId
	magisterClassId = _.find(user.classInfos, (ci) -> EJSON.equals ci.id, goaledSchedule.classId).magisterId

	# // grades
	grades = _.forEach r, (g) -> g._grade = gradeConverter g.grade()
	endGrades = _.filter grades, (g) -> _.contains ["e-jr", "eind"], g.type().header()?.toLowerCase()

	gradesOtherClasses = _.reject(endGrades, (g) -> g.class().id() isnt magisterClassId)
	gradeWeightSum = (
		sum = 0
		sum += g.weight() for g in _.filter grades, (g) -> g.class().id() is magisterClassId and g.type().type() isnt 2
		sum
	)

	avgOtherClasses = Helpers.getAverage gradesOtherClasses, (g) -> g.grade()
	avgCurrentClass = _.find endGrades, (g) -> g.class().id() is magisterClassId

	avgCompared = Math.round 100 - ((avgCurrentClass / avgOtherClasses) * 100)

	someClassesInsufficient = _.some gradesOtherClasses, (g) -> g.grade() < 5.5
	# \\ grades

	exceptionCase = switch
		when avgCurrentClass < 5.5 then 1
		when someClassesInsufficient then 2
		else 0

	exceptionPoints = switch
		when exceptionCase is 0 # get average with one point extra
			newAverage = (
				if avgCurrentClass >= 9.5 then 10
				else Math.ceil(avgCurrentClass - .4) + .5
			)
			neededGrade = ((newAverage * goaledSchedule.weight) + (newAverage * gradeWeightSum) - avgCurrentClass) / goaledSchedule.weight
			switch
				when neededGrade is 1 then 1
				when _.contains [2..3], neededGrade then 2
				when _.contains [4..5], neededGrade then 3
				when _.contains [6..7], neededGrade then 4
				when _.contains [8..9], neededGrade then 5
				when neededGrade >= 10 then 6

		when exceptionCase is 1 # get average to 5.5
			neededGrade = ((5.5 * goaledSchedule.weight) + (5.5 * gradeWeightSum) - avgCurrentClass) / goaledSchedule.weight
			switch
				when neededGrade is 1 then 1
				when neededGrade is 2 then 2
				when _.contains [3..4], neededGrade then 3
				when _.contains [5..6], neededGrade then 4
				when _.contains [7..8], neededGrade then 5
				when neededGrade >= 9 then 6

		else # stay same grade
			neededGrade = ((avgCurrentClass * goaledSchedule.weight) + (avgCurrentClass * gradeWeightSum) - avgCurrentClass) / goaledSchedule.weight
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

	return avgPoints + exceptionPoints + 7
	# TODO:
	# Should actually be `avgPoints + exceptionPoints + understanding + difficulty` later.
	#
	# We fill it now in with 7 points so that we won't get a real issue / gap between data later
	# when the schedular is fully finished. I don't know if we keep the database from the pilot
	# but if we do this should prevent issues coming up later.

###*
# Calculate the difficulty for the given amount of exercises based on
# the given grade average and last grade.
# @method calculateExercisePriority
# @param classGradeAverage {Number} The average grade of the class the exercises are for.
# @param classLastGrade {Number} The last grade of the class the exercises are for.
# @param [exerciseAmount=7] {Number} The amount of exercises.
# @return {Object} { points: {Number} The amount of points, timeNeeded: {Number} The time in minutes needed, daysInfront: {Number} The amount of days to begin working before the deadline }
###
@calculateExercisePriority = (classGradeAverage, classLastGrade, exerciseAmount = 7) ->
	points = 0

	points += 3 * switch
		when exerciseAmount <= 5 then 1
		when exerciseAmount > 5 and exerciseAmount <= 10 then 2
		when exerciseAmount > 10 and exerciseAmount <= 15 then 3
		when exerciseAmount > 15 then 4
		else 2

	points += 2 * switch
		when classGradeAverage >= 7 then 1
		when classGradeAverage < 7 and classGradeAverage >= 5.5 then 2
		when classGradeAverage < 5.5 and classGradeAverage >= 4 then 3
		when classGradeAverage < 4 then 4
		else 2

	points += switch
		when classLastGrade >= 6 then 1
		when classLastGrade < 6 and classLastGrade >= 4 then 2
		when classLastGrade < 4 and classLastGrade >= 3 then 3
		when classLastGrade < 3 then 4
		else 2

	timeNeeded = daysInfront = 0
	switch
		when points is 24
			timeNeeded = 90
			daysInfront = 4

		when points < 24 and points >= 19
			timeNeeded = 60
			daysInfront = 3

		when points < 19 and points >= 14
			timeNeeded = 30
			daysInfront = 2

		when points < 14
			timeNeeded = 15
			daysInfront = 1

	return { points, timeNeeded, daysInfront }

class @DateInfo
	@availableTimeEnum:
		none  : 0
		little: 1 # bias 12+
		normal: 2 # bias 14+
		much  : 3 # bias 16+

	@aviableTimeEnumMatch: (t) -> _.contains _.values(root.DateInfo.availableTimeEnum), t

	constructor: (@_weekDay, @_availableTime) ->
		@_className = "DateInfo"

		@date = root.getset "_date", Date
		@weekday = root.getset "_weekDay", (w) -> _.contains [0..6], w
		@availableTime = root.getset  "_availableTime", root.DateInfo.aviableTimeEnumMatch

	@_match: (dateInfo) ->
		return Match.test dateInfo, Match.ObjectIncluding
				_date: Date
				_availableTime: root.DateInfo.aviableTimeEnumMatch

	bias: ->
		return switch
			when @availableTime() is 0 then 0
			when @availableTime() is 1 then 12
			when @availableTime() is 2 or !@availableTime()? then 14
			when @availableTime() is 3 then 16

class @SchedularPrefs
	###*
	# Constructor for the SchedularPrefs class.
	#
	# @method constructor
	###
	constructor: ->
		@_className = "SchedularPrefs"

		@_dateInfos = []

		@dates = root.getset "_dateInfos", [Date]

	bias: (givenDate) ->
		date = _.find @dates(), (d) -> EJSON.equals d.date()?.date(), givenDate.date()
		date ?= _.find @dates(), (d) -> d.weekday() is Helpers.weekDay(givenDate)
		return if date? then date.bias() else 14

class TimeHolder
	constructor: ->
		@_dates = []

	getset: (date, biasPenalty, overwrite = false) ->
		check date, Date
		check biasPenalty, Match.Optional Number

		dateInfo = @_dates.smartFind date, (d) -> d.date
		if biasPenalty?
			if dateInfo?
				if overwrite
					dateInfo.biasPenalty = biasPenalty
				else
					dateInfo.biasPenalty -= biasPenalty
			else
				dateInfo = {date, biasPenalty}
				@_dates.push dateInfo

		return dateInfo ? { date, biasPenalty: 0 }

class @Schedular
	constructor: ->
		@_id = new Meteor.Collection.ObjectID()
		@_className = "Schedular"

		@_modules = Schedular.defaultModules[..]

		@schedularPrefs = root.getset "_schedularPrefs", root.SchedularPrefs._match
		@modules = root.getset "_modules", [Schedular._moduleMatch], no

	@_moduleMatch: (m) ->
		return Match.test m, Match.ObjectIncluding
				name: String
				description: String
				author: String
				func: Function
				moduleStorage: Match.Any

	addModule: (module) ->
		check module, Schedular._moduleMatch
		modules.push module

	removeModule: (module) ->
		check module, Schedular._moduleMatch
		item = @modules().smartFind module.name, (m) -> m.name
		_.remove @_modules, item

	setModuleEnabledState: (module, enabled) -> @modules().smartFind(module.name, (m) -> m.name).enabled = enabled

	biasToday: ->
		minuteTracker?.depend?()
		@schedularPrefs().bias new Date

	@defaultModules: [
		{
			name: "Vocabulary"
			description: "Super basic vocabulary planner"
			author: "Lieuwe Rooijakkers"
			func: ->
				return if !@currentPara.isVocabulary() or @leftDays < 5 or @leftDays / @leftParas.length < 2.25

				console.log "currentPara is vocabulary and should be repeated!" if @debug

				return [
					{ paragraph: @currentPara, date: @currentDate.addDays(1, yes), priority: Math.ceil @currentPara.priority / 2 }
					{ paragraph: @currentPara, date: @currentDate.addDays(2, yes), priority: Math.ceil @currentPara.priority / 4 }
				]
			moduleStorage: null
			firstRun: yes
			enabled: yes
		}
	]

	@_languages: [
		"engels"
		"duits"
		"frans"
		"nederlands"
		"chinees"
		"spaans"
		"je moeder"
	]

	schedule: (user = Meteor.user()) ->
		timeHolder = new TimeHolder
		goaledSchedules = GoaledSchedules.find(
			parsedData: $exists: yes
			ownerId: user._id
			dueDate: $gte: Date.today().addDays(2)
		).fetch()

		magisterResult "grades", (e, r) ->
			pushFilledGrade = _helpers.asyncResultWaiter r.length, (grades) ->
				for gS in goaledSchedules
					gS.__class = Classes.findOne gS.classId
					gS.__isLanguage = _.any Schedular._languages, (l) -> gS.__class.name.trim().toLowerCase().indexOf(l) is 0
					tasks = []

					if gS.parsedData.chapterData.length isnt 0 # chapters known
						if gS.__isLanguage
							if gS.parsedData.chapterData.values.length is 1 # one chapter.
								chapter = gS.parsedData.chapterData.values[0]
								tasks.push new Task(
									"Overhoor hoofdstuk #{chapter} voor toets morgen.",
									null,
									chapter,
									null,
									gS.dueDate.date().addDays(-1, yes),
									0,
									yes,
									"dumbass"
								)
								tasks.push new Task(
									"Herhaal grammatica en woorden hoofdstuk #{chapter} voor toets overmorgen.",
									null,
									chapter,
									null,
									gS.dueDate.date().addDays(-2, yes),
									0,
									yes,
									"dumbass"
								)
								tasks.push new Task(
									"Grammatica hoofdstuk #{chapter} leren.",
									null,
									chapter,
									null,
									gS.dueDate.date().addDays(-3, yes),
									0,
									no,
									"dumbass"
								)
								tasks.push new Task(
									"Woorden hoofdstuk #{chapter} leren.",
									null,
									chapter,
									null,
									gS.dueDate.date().addDays(-4, yes),
									0,
									no,
									"dumbass"
								)
							else # more than 1 chapter.
								console.log "."

						else # not a language.
							daysAmount = gS.parsedData.chapterData[0].values.length
							tasks.push new Task(
								"Hoofdstukken #{gS.parsedData.chapterData[0].values.join ", "} overhoren voor morgen",
								null,
								gS.parsedData.chapterData[0].values,
								null,
								gS.dueDate.date().addDays(-1, yes),
								0,
								yes,
								"dumbass"
							)
							tasks.push new Task(
								"Hoofdstukken #{gS.parsedData.chapterData[0].values.join ", "} herhalen voor overmorgen.",
								null,
								gS.parsedData.chapterData[0].values,
								null,
								gS.dueDate.date().addDays(-2, yes),
								0,
								yes,
								"dumbass"
							)

							for i in [0...daysAmount]
								tasks.push new Task(
									"Leren hoofdstuk #{gS.parsedData.chapterData[0].values[i]}.",
									null,
									gS.parsedData.chapterData[0].values[i],
									null,
									gS.dueDate.date().addDays(-(daysAmount - i), yes),
									0,
									no,
									"dumbass"
								)

					else if gS.parsedData.paragraphData.length isnt 0 # only paragraphs known
						dayRange = moment(gS.dueDate.date()).diff Date.today(), "days"
						continue if dayRange < 3

						dates = []
						for i in [0...dayRange - 2]
							dates.push new Date.addDays i

						paragraphsPerDay = gS.parsedData.paragraphData.length / dayRange - 2
						paragraphs = gS.parsedData.paragraphData[0].values[..]

						tasks.push new Task(
							"§ #{gS.parsedData.parargraphData[0].values.join ", "} overhoren voor toets morgen",
							null,
							null,
							gS.parsedData.paragraphData.values,
							gS.dueDate.date().addDays(-2, yes),
							0,
							yes,
							"dumbass"
						)
						tasks.push new Task(
							"§ #{gS.parsedData.parargraphData[0].values.join ", "} overhoren voor toets overmorgen",
							null,
							null,
							gS.parsedData.paragraphData.values,
							gS.dueDate.date().addDays(-1, yes),
							0,
							yes,
							"dumbass"
						)

						for date, i in dates
							tasks.push new Task(
								"leren § #{gS.parsedData.parargraphData[0].values.join ", "}.",
								null,
								null,
								paragraphs[i...paragraphsPerDay],
								date,
								0,
								yes,
								"dumbass"
							)

					else # nothing known
						date = gS.dueDate.addDays -4, yes

						for i in [0..3]
							if i is 3
								tasks.push new Task(
									"#{gS.__class.name} herhalen voor morgen.",
									null,
									null,
									null,
									_.clone(date),
									0,
									yes,
									"dumbass"
								)
							else
								tasks.push new Task(
									"Leren voor #{gS.__class.name}.",
									null,
									null,
									null,
									_.clone(date),
									0,
									no,
									"dumbass"
								)
							date = date.addDays 1, yes

					GoaledSchedules.update gS._id, $set: { tasks }

			for grade in r when not grade._filled
				grade.fillGrade pushFilledGrade

#	###*
#	# Schedules the current goaledSchedules for `user`.
#	# @method schedule
#	# @property user {User} The user to schedule for, default to `Meteor.user()`.
#	###
#	schedule: (user = Meteor.user()) ->
#		timeHolder = new TimeHolder
#		goaledSchedules = GoaledSchedules.find(
#			parsedData: $exists: yes
#			ownerId: user._id
#			dueDate: $gte: Date.today().addDays(2)
#		).fetch()
#
#		magisterResult "grades", (e, r) ->
#			pushFilledGrade = _helpers.asyncResultWaiter r.length, (grades) ->
#				paras = []
#				for goaledSchedule in goaledSchedules
#					goaledSchedule.repeatDates = []
#
#					paragraphs = []
#					for pd in goaledSchedule.parsedData.paragraphData
#						for value in pd.values
#							paragraphs.push { value, chapter: pd.parentChapter }
#
#					currentDate = goaledSchedule.dueDate.addDays -1 * (paragraphs.length / 2), yes
#					bookId = _.find(user.profile.classInfos, (ci) -> EJSON.equals ci.id, goaledSchedule.classId)?.bookId
#
#					for p in paragraphs
#						task = _.filter goaledSchedule.tasks, (t) ->
#							sameBook = if bookId? and t.bookId? then EJSON.equals(t.bookId, bookId) else yes
#							sameChapter = t.chapter is p.chapter
#							sameParagraph = t.paragraph is p.value
#
#							return sameBook and sameChapter and sameParagraph
#
#						if task?
#							continue if task.isDone # If it's already done there's no need to plan it in, right?
#							GoaledSchedules.update goaledSchedule._id, $pull: items: task # If it isn't already done we need to plan it, before that we need to remove the old planned scheduleItem.
#
#						p.deadline = goaledSchedule.dueDate
#						p.goaledSchedule = goaledSchedule
#						p.priority = priority
#
#						paras.push
#
#					parasForCurrentDay = []
#					shouldRepeat = Helpers.daysRange(Date.today(), goaledSchedule.dueDate) > 5 and Helpers.daysRange(Date.today(), goaledSchedule.dueDate) / paragraphs.length >= 1.75
#					for p in _.sortBy(paragraphs, (p) -> p.priority).reverse()
#						if shouldRepeat
#							p.deadline = goaledSchedule.dueDate.addDays -1 * (paragraphs.length / 2), yes
#							p.biasPenalty = p.priority
#							p.repeatDate = currentDate
#							parasForCurrentDay.push p
#							goaledSchedule.addItem p.name(), p._id, _.clone(currentDate), p.priority, yes, "repeater"
#
#							if parasForCurrentDay.length is 2
#								parasForCurrentDay = []
#								goaledSchedule.repeatDates.push _.clone currentDate
#								currentDate = currentDate.addDays 1, yes
#
#				leftParas = _.sortBy(paras, (p) -> p.priority).reverse()
#
#				currentDate = Date.today()
#
#				dateInfos = []
#				parasForCurrentDay = []
#
#				currentParasPosition = 0
#				while leftParas.length isnt 0 and currentParasPosition <= leftParas.length # Fill the days where there's enough place for the paragraphs
#					biasDifferenceForCurrentDay = @schedularPrefs().bias currentDate
#					dayNotAvailable = biasDifferenceForCurrentDay is 0
#
#					if p.biasPenalty? and EJSON.equals currentDate, leftParas[currentParasPosition].repeatDate
#						biasDifferenceForCurrentDay -= p.biasPenalty
#
#					biasDifferenceForCurrentDay -= timeHolder.getset(currentDate).biasPenalty
#
#					# We can't plan in something that's already due.
#					if currentParasPosition is leftParas.length then break
#					else if Helpers.daysRange(currentDate, leftParas[currentParasPosition].deadline) <= 0
#						currentParasPosition += 1
#						continue
#
#					# Fill the heaviest paragraph in as first.
#					if biasDifferenceForCurrentDay isnt 0
#						parasForCurrentDay.push leftParas[currentParasPosition]
#						biasDifferenceForCurrentDay -= leftParas[currentParasPosition].priority
#						leftParas.remove leftParas[currentParasPosition]
#
#					# Modules! <3
#					for m in _.filter(@modules(), (m) -> m.enabled)
#						try
#							result = m.func.bind({
#								currentPara: leftParas[currentParasPosition]
#								leftParas
#								dateInfos
#								parasForCurrentDay
#								currentDate
#								biasDifferenceForCurrentDay
#								dayNotAvailable
#								leftDays: Helpers.daysRange(currentDate, leftParas[currentParasPosition].deadline)
#								debug: false
#								timeHolder
#								moduleStorage: m.moduleStorage
#								firstRun: m.firstRun
#							})()
#							m.firstRun = no
#							if _.isArray result
#								for pData in result
#									timeHolder.getset pData.date, pData.priority
#									biasDifferenceForCurrentDay -= pData.priority if EJSON.equals currentDate, pData.date
#									pData.paragraph.goaledSchedule.addItem pData.paragraph.name(), pData.paragraph._id, _.clone(pData.date), pData.priority, no, m.name
#						catch e
#							Meteor.call "log", "warn", "Error while executing module: #{m.author}:#{m.name}; #{e.message} | Stack: #{e.stack}"
#
#					# fill in a paragraph if there's enough space
#					while biasDifferenceForCurrentDay > 0
#						possiblePara = _.find leftParas, (p) -> p.priority <= biasDifferenceForCurrentDay
#						if possiblePara?
#							parasForCurrentDay.push possiblePara
#							biasDifferenceForCurrentDay -= possiblePara.priority
#							leftParas.remove possiblePara
#						else break
#
#					# Apply it to the schedules.
#					for para in parasForCurrentDay
#						GoaledSchedules.update $push: items, new Task para.name(), para._id, _.clone(currentDate), para.priority, no, "stock"
#					dateInfos.push
#						date: currentDate
#						biasDifference: biasDifferenceForCurrentDay
#						dayNotAvailable: dayNotAvailable
#
#					# reset.
#					parasForCurrentDay = []
#					currentDate = currentDate.addDays 1, yes
#
#				# Fill the other paragraphs in.
#				for heaviestPara in _.sortBy(leftParas, (p) -> p.priority).reverse()
#					lightestDay = _.reject(_.sortBy(dateInfos, (d) -> d.biasDifference).reverse(), (d) -> d.dayNotAvailable)[0]
#
#					GoaledSchedules.update $push: items: new task heaviestPara.name(), heaviestPara._id, lightestDay.date, heaviestPara.priority, no, "overflower"
#					lightestDay.biasDifference -= heaviestPara.priority
#
#			for grade in r when not grade._filled
#				grade.fillGrade pushFilledGrade
