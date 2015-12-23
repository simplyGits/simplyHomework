class @Parser
	@afterKeywords = [
		"van"
		"in"
		"of"
		"from"
	]

	@ignoreCharsRegexp = /[,:\s;\.]/ig

	###*
	# Parses the given description for tests, homework and quizzes.
	# As well as the paragraphs, chapters and exercises.
	#
	# @method parseDescription
	# @param description {String} The description to parse.
	# @param originalType {String} The original type for the homework of this description, most probaly as filled in by the teacher and given received through Magister.
	# @return {ParsedData} The data parsed as a ParsedData instance.
	###
	@parseDescription: (description, originalType) ->
		# TODO: Analyze the data (maybe with an neural network?) to make it smarter and eliminate false alarms:
		# >>>>> We REALLY need a way for the users to flag false alarms so we won't plan in homework as tests.
		#		For example 'pw opgaven 1, 5 en 10' is flagged as a 'test', while my teacher means 'proefwerkopgaven' a special thing in our book.
		#		By comparing the data with the original description and maybe static analysis and the input / feedback of the user we can train our detection system.
		#		The best way maybe is a neural network.

		type = originalType
		unless type?
			type = "homework"
			type = "quiz" if /^((so)|((luister ?)?toets)|(schriftelijke overhoring))/i.test description
			type = "test" if /^((proefwerk)|(pw)|(examen)|(tentamen))/i.test description

		# FIXME: Clean this shit up.
		# TODO: This parsing algorithm is still pretty dumb. Could be smarter, no?

		chapterData = @_extractData description, "chapter"
		paragraphData = @_extractData description, "paragraph"
		exerciseData = @_extractData description, "exercise"

		words = _.without (w.replace(/\W[\W_]\S*/ig, "") for w in description.split(' ')), "" # split description and filter out punctuation marks
		_words = words[..] # unaltered copy.

		for extractedData in paragraphData
			# Split the raw form of the current parsed paragraph info.
			originSplitted = extractedData.origin.split ' '

			# Get the indexes of the first and last words of the paragraph info in the words array.
			firstWordIndex = _.indexOf words, _.first(originSplitted)
			lastWordIndex = _.indexOf words, _.last(originSplitted)
			words.splice firstWordIndex, lastWordIndex # Remove between the indexes on the words array to make sure we aren't using the same indexes later.

			if _.contains Parser.afterKeywords, words[lastWordIndex + 1] # Next word after the paragraph block indicates a word that tells which chapter it's part from
				# Get the first chapter introduced AFTER the current paragraph.
				parentChapter = _.find chapterData, (data) -> words[..firstWordIndex].join(" ").indexOf(data.origin) is -1
				extractedData.parentChapter = chapterData.values[0]
			else
				parentChapter = _.findLast chapterData, (data) ->
					isBeforeParagraph = words[..firstWordIndex].join(" ").indexOf(data.origin) > -1

					# Gets the last word of the chapter info and checks if its close (3 indexes away).
					isClose = firstWordIndex - _.lastIndexOf(words, _.last(data.origin.split(" ").remove(Parser.ignoreCharsRegexp, ""))) <= 3

					return isBeforeParagraph and isClose

				extractedData.parentChapter = _.last parentChapter?.values ? []

		words = _words[..] # restore unaltered copy since we need the locations of the paragraphs still in tact.
		for extractedData in exerciseData # totally not a copy paste. ;)
			# Split the raw form of the current parsed exercise info.
			originSplitted = extractedData.origin.split ' '

			# Get the indexes of the first and last words of the exercise info in the words array.
			firstWordIndex = _.indexOf words, _.first(originSplitted)
			lastWordIndex = _.indexOf words, _.last(originSplitted)
			words.splice firstWordIndex, lastWordIndex # Remove between the indexes on the words array to make sure we aren't using the same indexes later.

			if _.contains Parser.afterKeywords, words[lastWordIndex + 1] # Next word after the exercise block indicates a word that tells which paragraph it's part from
				# Get the first paragraph introduced AFTER the current exercise.
				parentParagraph = _.find paragraphData, (data) -> words[..firstWordIndex].join(" ").indexOf(data.origin) is -1
				extractedData.parentParagraph = paragraphData.values[0]
				extractedData.parentChapter = parentParagraph.parentChapter
			else
				parentParagraph = _.findLast paragraphData, (data) ->
					isBeforeExercise = words[..firstWordIndex].join(" ").indexOf(data.origin) > -1

					# Gets the last word of the exercise info and checks if its close (3 indexes away).
					isClose = firstWordIndex - _.lastIndexOf(words, _.last(data.origin.split(" ").remove(Parser.ignoreCharsRegexp, ""))) <= 3

					return isBeforeExercise and isClose

				extractedData.parentParagraph = _.last parentParagraph?.values ? []
				extractedData.parentChapter = parentParagraph?.parentChapter

				unless extractedData.parentChapter?
					parentChapter = _.findLast chapterData, (data) ->
						isBeforeParagraph = words[..firstWordIndex].join(" ").indexOf(data.origin) > -1

						# Gets the last word of the chapter info and checks if its close (5 indexes away).
						isClose = firstWordIndex - _.lastIndexOf(words, _.last(data.origin.split(" "))) <= 5

						return isBeforeParagraph and isClose

					extractedData.parentChapter = _.last parentChapter?.values ? []

		return new ParsedData description, chapterData, paragraphData, exerciseData, type

	###*
	# Extracts the chapters, paragraphs from the description
	#
	# @method _extractData
	# @param description {String} The description to parse.
	# @param parseType {String} The type of thing to extract.
	# @return {ExtractedData[]} An array containing ExtractedData instances containing the data extracted from the description.
	###
	@_extractData: (description, parseType) ->
		regexes = switch parseType
			when "chapter" then ChapterExps
			when "paragraph" then ParagraphExps
			when "exercise" then ExerciseExps

		data = []
		for regex in regexes
			matches = Helpers.allMatches regex, description

			for match in matches
				left = "#{match}"
				values = []

				tills = Helpers.allMatches /\b\d+ ?(-|en|t\/?m|tot( en met)?) ?\d+/i, left # Check for tills ('t/m' and ',' for example).
				left = (left.replace s, "" for s in tills) # Tills have a higher priority, see hoofdstuk 1, 5 t/m 8 for example. 5 t/m 8 should be parsed as first and 1 should be added after that.

				adds = Helpers.allMatches /\b\d+/g, left # Check for additions. (Just seperate numbers).

				for s in adds
					values.push +s

				for s in tills
					numbers = (+v for v in Helpers.allMatches /\d+/g, s)
					values = values.concat [_.first(numbers).._.last(numbers)]

				data.push new ExtractedData match, _.sortBy values

		return data

class ExtractedData
	constructor: (@origin, @values) ->
		@parentChapter = null
		@parentParagraph = null

class ParsedData
	constructor: (@originalDescription, @chapterData, @paragraphData, @exerciseData, @homeworkType) -> return
