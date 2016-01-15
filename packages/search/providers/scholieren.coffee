Search.provide 'scholieren', [
	'report'
], ({ query, user, classIds }) ->
	res = []
	for classId in classIds
		c = Classes.findOne _id: classId
		classInfo = _.find getClassInfos(user._id), id: classId

		bookName = Books.findOne(classInfo.bookId)?.title ? ''
		query = "#{normalizeClassName c.name} #{bookName} #{query}"
		res = res.concat Scholieren.getReports(query).map (item) ->
			_.extend item,
				type: 'report'
				filtered: yes
	res
