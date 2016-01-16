Search.provide 'scholieren', [
	'report'
], ({ query, user, classes }) ->
	res = []
	for c in classes
		classInfo = _.find getClassInfos(user._id), id: c._id

		bookName = Books.findOne(classInfo.bookId)?.title ? ''
		query = "#{normalizeClassName c.name} #{bookName} #{query}"
		res = res.concat Scholieren.getReports(query).map (item) ->
			_.extend item,
				type: 'report'
				filtered: yes
	res
