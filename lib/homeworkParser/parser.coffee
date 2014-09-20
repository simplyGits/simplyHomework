root = @

class @Parser
	@chapterAfterKeywords = [ "van"
		"in"
		"of"
		"from"
	]

	@parseTypeEnum:
		chapter: 1
		paragraph: 2
		page: 3

	###*
	# Parses the given Homework instance or a homework description
	#
	# @method parseHomework
	# @param homework {Homework} The Homework instance to parse.
	# @return {ParsedData} The data parsed as a ParsedData instance.
	###
	@parseHomework: (homework) ->
		description = homework.description()

		chapterData = Parser.extractChapterData(description)
		paragraphData = Parser.extractParagraphData(description)
		pageData = Parser.extractPageData(description)

		words = _.without (w.replace(/\W[\W_]\S*/ig, "") for w in description.split(' ')), "" # filter out punctuation marks

		for extractedData in paragraphData
			originSplitted = extractedData.origin.split ' '
			firstWordIndex = _.indexOf words, _.first(originSplitted)
			lastWordIndex = _.indexOf words, _.last(originSplitted)
			if _.contains Parser.chapterAfterKeywords, words[lastWordIndex + 1]
				extractedData.parentChapter = _.find chapterData, (cd) -> !Helpers.contains words[..firstWordIndex].join " ", cd.origin
			else
				extractedData.parentChapter = _.last(_.filter(chapterData, (cd) -> Helpers.contains(words[..firstWordIndex].join(" "), cd.origin) and firstWordIndex - _.indexOf(words, _.last(cd.origin.split(' '))) <= 3))

		return new ParsedData description, chapterData, paragraphData, pageData

	@extractChapterData: (description) -> Parser._extractData description, Parser.parseTypeEnum.chapter
	@extractParagraphData: (description) -> Parser._extractData description, Parser.parseTypeEnum.paragraph
	@extractPageData: (description) -> Parser._extractData description, Parser.parseTypeEnum.page

	###*
	# Extracts the chapters, paragraphs or pages from the description
	#
	# @method _extractData
	# @param description {String} The description to parse from.
	# @param parseType {Number} A value of parseTypeEnum telling which regex should be used.
	# @return {Array} An array containing ExtractedData instances containing the data extracted from the description.
	###
	@_extractData: (description, parseType) ->
		if !_.contains _.values(Parser.parseTypeEnum), parseType # Type checking on 'parseType'
			throw new root.ArgumentException "parseType", "parseType isn't a valid value from parseTypeEnum"

		data = []
		for regex in (if parseType is 1 then ChapterExps else if parseType is 2 then ParagraphExps else PageExps)
			matches = root.Helpers.allMatches regex, description

			for match in matches
				values = ((Number) v for v in root.Helpers.allMatches /[0-9]+/ig, match ) # get ALL the numbers. :P

				if /([0-9]+ ?t[\/\\]?m ?[0-9]+)|([0-9]+ ?- ?[0-9]+)|([0-9]+ ?tot en met ?[0-9]+)/i.test match
					values = [_.first(values).._.last(values)] # Get a range between the values (including the last one).
				else if /[0-9]+ ?tot ?[0-9]+/i.test match
					values = [_.first(values)..._.last(values)]	# Get a range between the values (NOT including the last one).

				data.push new ExtractedData match, values
		return data

class ExtractedData
	constructor: (@origin, @values) -> @parentChapter = null

class ParsedData
	constructor: (@originalDescription, @chapterData, @paragraphData, @pageData) -> return