Search.provide 'scholieren', ({ query, user, classes, keywords }) ->
	if 'report' not in keywords then []
	else
		res = []
		for c in classes
			classInfo = _.find getClassInfos(user._id), id: c._id

			bookName = Books.findOne(classInfo.bookId)?.title ? ''
			query = "#{normalizeClassName c.name} #{bookName} #{query}"
			res = res.concat(
				_(Scholieren.getReports query)
					.filter (item) ->
						reg = /^.+\(([^\)]+)\)$/
						match = reg.exec item.title
						not match? or match[1].toLowerCase() is bookName.toLowerCase()

					.map (item) ->
						item.title = item.title.replace /\([^\)]+\)$/, ''
						_.extend item,
							type: 'report'
							filtered: yes

					.value()
			)
		res
