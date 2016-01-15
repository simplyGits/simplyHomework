Search.provide 'projects', ({ query, user, classIds }) ->
	Projects.find({
		participants: user._id
		classId: (
			if classIds.length > 0 then { $in: classIds }
			else { $nin: classIds }
		)
	}, {
		fields:
			participants: 1
			name: 1
			classId: 1

		transform: (p) -> _.extend p,
			type: 'project'
			title: p.name
	}).fetch()
