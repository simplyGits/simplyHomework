root = @

class @DateInfo
	@availableTimeEnum:
		none  : 0
		little: 1 # bias 12+
		normal: 2 # bias 14+
		much  : 3 # bias 16+

	@aviableTimeEnumMatch: (t) -> _.contains _.values(root.DateInfo.availableTimeEnum), t

	constructor: (@_parent, @_weekDay, @_availableTime) ->
		@_className = "DateInfo"
		@dependency = new Deps.Dependency

		@date = root.getset "_date", Date
		@weekday = root.getset "_weekDay", (w) -> _.contains [0..6], w
		@availableTime = root.getset  "_availableTime", root.DateInfo.aviableTimeEnumMatch

	_setDeps: ->
		Deps.autorun (computation) => # Calls the dependency of the sender object, unless it's null
			@dependency.depend()
			@_parent.dependency.changed() if @_parent? and !computation.firstRun

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
	# @param _parent {Object} The creator of this object.
	###
	constructor: (@_parent) ->
		@_className = "SchedularPrefs"
		@dependency = new Deps.Dependency

		@_dateInfos = []

		@dates = root.getset "_dateInfos", [Date]

		@addDateInfo = root.add "_dateInfos", "DateInfo"
		@removeDateInfo = root.remove "_dateInfos", "DateInfo"

	_setDeps: ->
		Deps.autorun (computation) => # Calls the dependency of the sender object, unless it's null
			@dependency.depend()
			@_parent.dependency.changed() if @_parent? and !computation.firstRun
		
	@_match: (schedulePrefs) ->
		return Match.test schedulePrefs, Match.ObjectIncluding
				_disallowedDates : [Date]

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
	constructor: (@_parent, @userId) ->
		@_id = new Meteor.Collection.ObjectID()
		@_className = "Schedular"

		@dependency = new Deps.Dependency

		@_modules = Schedular.defaultModules[..]

		@schedularPrefs = root.getset "_schedularPrefs", root.SchedularPrefs._match
		@modules = root.getset "_modules", [Schedular._moduleMatch], no

	_setDeps: ->
		Deps.autorun (computation) => # Calls the dependency of the sender object, unless it's null
			@dependency.depend()
			@_parent.dependency.changed() if @_parent? and !computation.firstRun

	@_moduleMatch: (m) ->
		return Match.test m, Match.ObjectIncluding
				name: String
				description: String
				author: String
				func: Function
				moduleStorage: Match.Any

	user: -> Meteor.users.findOne @userId

	addModule: (module) ->
		check module, Schedular._moduleMatch
		modules.push module
		@dependency.changed()

	removeModule: (module) ->
		check module, Schedular._moduleMatch
		item = @modules().smartFind module.name, (m) -> m.name
		_.remove @_modules, item
		@dependency.changed()

	setModuleEnabledState: (module, enabled) -> @modules().smartFind(module.name, (m) -> m.name).enabled = enabled

	biasToday: -> @schedularPrefs().bias new Date

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

	schedule: -> 
		timeHolder = new TimeHolder
		goaledSchedules = _.filter Get.goaledSchedules(_homework: { $exists: true }, ownerId: @userId).fetch(), (gS) => Helpers.daysRange(Date.today(), gS.homework().dueDate()) >= 2

		paras = []
		for gS in goaledSchedules
			gS.repeatDates = []

			book = _.find(Get.classes(gS.classId()).fetch()[0].books(), (b) => EJSON.equals(b._id, _.find(@user.profile.classInfos, (classInfo) => EJSON.equals classInfo.id, gS.classId()).bookId))
			paragraphs = _.sortBy(gS.homework().getParsedParagraphs(book), (p) => p.priority).reverse()

			currentDate = gS.dueDate().addDays -1 * (paragraphs.length / 2), yes

			for p in paragraphs
				if (scheduleItem = gS.items().smartFind p._id, (sI) -> sI.paragraphId())?
					continue if scheduleItem.isDone() # If it's already done there's no need to plan it in, right?
					gS.removeItem scheduleItem # If it isn't already done we need to plan it, before that we need to remove the old planned scheduleItem.

				p.deadline = gS.dueDate()
				p.goaledSchedule = gS
				p.priority = p.calculatePriority gS
				paras.push p

			parasForCurrentDay = []
			shouldRepeat = Helpers.daysRange(Date.today(), gS.dueDate()) > 5 and Helpers.daysRange(Date.today(), gS.duedate()) / paragraphs.length >= 1.75
			for p in _.sortBy(paragraphs, (p) => p.priority).reverse()
				# Make repeat ScheduleItems if needed.
				if shouldRepeat
					p.deadline = gS.dueDate().addDays -1 * (paragraphs.length / 2), yes
					p.biasPenalty = p.priority
					p.repeatDate = currentDate
					parasForCurrentDay.push p
					gS.addItem p.name(), p._id, _.clone(currentDate), p.priority, yes, "repeater"

					if parasForCurrentDay.length is 2
						parasForCurrentDay = []
						gS.repeatDates.push _.clone currentDate
						currentDate = currentDate.addDays 1, yes

		leftParas = _.sortBy(paras, (p) => p.priority).reverse()

		currentDate = Date.today()

		dateInfos = []
		parasForCurrentDay = []

		currentParasPosition = 0
		while leftParas.length isnt 0 and currentParasPosition <= leftParas.length # Fill the days where there's enough place for the paragraphs
			biasDifferenceForCurrentDay = @schedularPrefs().bias currentDate
			dayNotAvailable = biasDifferenceForCurrentDay is 0

			if p.biasPenalty? and EJSON.equals currentDate, leftParas[currentParasPosition].repeatDate
				biasDifferenceForCurrentDay -= p.biasPenalty

			biasDifferenceForCurrentDay -= timeHolder.getset(currentDate).biasPenalty
			
			# We can't plan in something that's already due.
			if currentParasPosition is leftParas.length then break
			else if Helpers.daysRange(currentDate, leftParas[currentParasPosition].deadline) <= 0
				currentParasPosition += 1
				continue

			# Fill the heaviest paragraph in as first.
			if biasDifferenceForCurrentDay isnt 0
				parasForCurrentDay.push leftParas[currentParasPosition]
				biasDifferenceForCurrentDay -= leftParas[currentParasPosition].priority
				leftParas.remove leftParas[currentParasPosition]

			# Modules! <3
			for m in _.filter(@modules(), (m) => m.enabled)
				try
					result = m.func.bind({
						currentPara: leftParas[currentParasPosition]
						leftParas
						dateInfos
						parasForCurrentDay
						currentDate
						biasDifferenceForCurrentDay
						dayNotAvailable
						leftDays: Helpers.daysRange(currentDate, leftParas[currentParasPosition].deadline)
						debug: false
						timeHolder
						moduleStorage: m.moduleStorage
						firstRun: m.firstRun
					})()
					m.firstRun = no
					if _.isArray result
						for pData in result
							timeHolder.getset pData.date, pData.priority
							biasDifferenceForCurrentDay -= pData.priority if EJSON.equals currentDate, pData.date
							pData.paragraph.goaledSchedule.addItem pData.paragraph.name(), pData.paragraph._id, _.clone(pData.date), pData.priority, no, m.name
				catch e
					Meteor.call "log", "warn", "Error while executing module: #{m.author}:#{m.name}; #{e.message} | Stack: #{e.stack}"

			# fill in a paragraph if there's enough space
			while biasDifferenceForCurrentDay > 0
				possiblePara = _.find leftParas, (p) => p.priority <= biasDifferenceForCurrentDay
				if possiblePara?
					parasForCurrentDay.push possiblePara
					biasDifferenceForCurrentDay -= possiblePara.priority
					leftParas.remove possiblePara
				else break

			# Apply it to the schedules.
			para.goaledSchedule.addItem para.name(), para._id, _.clone(currentDate), para.priority, no, "stock" for para in parasForCurrentDay
			dateInfos.push
				date: currentDate
				biasDifference: biasDifferenceForCurrentDay
				dayNotAvailable: dayNotAvailable

			# reset.
			parasForCurrentDay = []
			currentDate = currentDate.addDays(1, yes)

		# Fill the other paragraphs in.
		for heaviestPara in _.sortBy(leftParas, (p) => p.priority).reverse()
			lightestDay = _.reject(_.sortBy(dateInfos, (d) => d.biasDifference).reverse(), (d) => d.dayNotAvailable)[0]

			heaviestPara.goaledSchedule.addItem heaviestPara.name(), heaviestPara._id, lightestDay.date, heaviestPara.priority, no, "overflower"
			lightestDay.biasDifference -= heaviestPara.priority

		@dependency.depend()
		return goaledSchedules

	debugSchedule: () -> # FAKED VALUES
		timeHolder = new TimeHolder
		debugFinal = []
		debugDueDate = Date.today().addDays(12)

		paras = []
		paragraphs = []
		for [0.._.random(10)]
			paragraphs.push
				calculatePriority: -> _.random(4, 21)
				name: -> _.random(1337)
				isVocabulary: -> if _.contains [0..3], _.random(5) then true else false

		paragraphs = _.sortBy(paragraphs, (p) => p.priority).reverse()
		currentDate = debugDueDate.addDays -1 * (paragraphs.length / 2), yes
		parasForCurrentDay = []
		console.log "paragraphs length: #{paragraphs.length} | amount of days: #{Helpers.daysRange(Date.today(), debugDueDate)}"
		shouldRepeat = Helpers.daysRange(Date.today(), debugDueDate) > 5 and Helpers.daysRange(Date.today(), debugDueDate) / paragraphs.length >= 1.75
		for p in paragraphs
			p.deadline = debugDueDate
			p.priority = p.calculatePriority()
			paras.push p

		for p in _.sortBy(paragraphs, (p) => p.priority).reverse()
			if shouldRepeat
				p.deadline = debugDueDate.addDays -1 * (paragraphs.length / 2), yes
				p.biasPenalty = p.priority
				p.repeatDate = currentDate
				parasForCurrentDay.push p
				console.log "planning paragraph for repeat (paragraphs length: #{paragraphs.length} | parasForCurrentDay length: #{parasForCurrentDay.length} | currentDate: #{currentDate.getDate()})"
				debugFinal.push new ScheduleItem null, "#{p.name()} REPEAT", p._id, _.clone(currentDate), p.priority, yes, "repeater"

				if parasForCurrentDay.length is 2
					parasForCurrentDay = []
					currentDate = currentDate.addDays 1, yes

		leftParas = _.sortBy(paras, (p) => p.priority).reverse()
		console.log "priorities of leftParas: #{(p.priority for p in leftParas)}"

		currentDate = Date.today()
		dateInfos = []
		parasForCurrentDay = []
		currentParasPosition = 0

		while leftParas.length isnt 0 and currentParasPosition <= leftParas.length # Fill the days where there's enough place for the paragraphs
			biasDifferenceForCurrentDay = @schedularPrefs().bias currentDate
			dayNotAvailable = biasDifferenceForCurrentDay is 0 
			
			if p.biasPenalty? and EJSON.equals currentDate, leftParas[currentParasPosition].repeatDate
				biasDifferenceForCurrentDay -= p.biasPenalty

			biasDifferenceForCurrentDay -= timeHolder.getset(currentDate).biasPenalty

			console.log "#{biasDifferenceForCurrentDay} + #{currentDate.getDate()}"

			# We can't plan in something that's already due.
			if currentParasPosition is leftParas.length then break
			else if Helpers.daysRange(currentDate, leftParas[currentParasPosition].deadline) <= 0
				currentParasPosition += 1
				continue

			# Fill the heaviest paragraph in as first.
			if biasDifferenceForCurrentDay isnt 0
				console.log "planning initial paragraph"
				parasForCurrentDay.push leftParas[currentParasPosition]
				biasDifferenceForCurrentDay -= leftParas[currentParasPosition].priority
				leftParas.remove leftParas[currentParasPosition]
				console.log "new biasDifference for #{currentDate.getDate()} is #{biasDifferenceForCurrentDay}"

			# Modules! <3
			for m in _.filter(@modules(), (m) => m.enabled)
				try
					break if !leftParas[currentParasPosition]?

					result = m.func.bind({
						currentPara: leftParas[currentParasPosition]
						leftParas
						dateInfos
						parasForCurrentDay
						currentDate
						biasDifferenceForCurrentDay
						dayNotAvailable
						leftDays: Helpers.daysRange(currentDate, leftParas[currentParasPosition].deadline)
						debug: true
						timeHolder
						moduleStorage: m.moduleStorage
						firstRun: m.firstRun
					})()
					m.firstRun = no					
					if _.isArray result
						for pData in result
							timeHolder.getset pData.date, pData.priority
							biasDifferenceForCurrentDay -= pData.priority if EJSON.equals currentDate, pData.date
							debugFinal.push new ScheduleItem null, pData.paragraph.name(), pData.paragraph._id, _.clone(pData.date), pData.priority, no, m.name
				catch e
					Meteor.call "log", "warn", "Error while executing module: #{m.author}:#{m.name}; #{e.message} | Stack: #{e.stack}"
					console.log e

			# Fill in a paragraph if there's enough space.
			while biasDifferenceForCurrentDay > 0
				possiblePara = _.find leftParas, (p) => p.priority <= biasDifferenceForCurrentDay
				if possiblePara?
					console.log "enough space left! planning!"
					parasForCurrentDay.push possiblePara
					biasDifferenceForCurrentDay -= possiblePara.priority
					leftParas.remove possiblePara
					console.log "new biasDifference for #{currentDate.getDate()} is #{biasDifferenceForCurrentDay}"
				else break

			# Apply it to the schedules.
			debugFinal.push new ScheduleItem null, para.name(), para._id, _.clone(currentDate), para.priority, no, "stock" for para in parasForCurrentDay
			dateInfos.push
				date: currentDate
				biasDifference: biasDifferenceForCurrentDay
				dayNotAvailable: dayNotAvailable

			# reset.
			parasForCurrentDay = []
			currentDate = currentDate.addDays(1, yes)

		# Fill the other paragraphs in.
		for heaviestPara in _.sortBy(leftParas, (p) => p.priority).reverse()
			lightestDay = _.reject(_.sortBy(dateInfos, (d) => d.biasDifference).reverse(), (d) => d.dayNotAvailable)[0]

			console.log "hit paras overflow (bias difference for day is #{lightestDay.biasDifference}; others are #{(d.biasDifference for d in _.reject(dateInfos, (d) => d.dayNotAvailable or d is lightestDay))} | date is #{lightestDay.date.getDate()})"
			debugFinal.push new ScheduleItem null, heaviestPara.name() + " OVERFLOWED", heaviestPara._id, lightestDay.date, heaviestPara.priority, no, "overflower"

			lightestDay.biasDifference -= heaviestPara.priority

		debugFinal = _.sortBy debugFinal, (s) => s.plannedDate()
		avg = Helpers.getAverage(dateInfos, (d) => d.biasDifference)

		console.log "Bias offsets for days #{(d.biasDifference for d in dateInfos)} (average: #{avg})"
		console.log if avg >= 0 then "yay" else if avg < -2 then "RIP" else ":c"

		@dependency.depend()
		return _.sortBy debugFinal, (s) => s.plannedDate()