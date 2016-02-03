Search.provide 'studyUtil files', ({ user, classIds }) ->
	studyUtils = StudyUtils.find({
		userIds: user._id
		classId: (
			if classIds.length > 0 then { $in: classIds }
			else { $nin: classIds } # match all classes
		)
	}, {
		fields:
			classId: 1
			userIds: 1
			files: 1
	}).fetch()

	_(studyUtils)
		.pluck 'files'
		.flatten()
		.map (f) ->
			type: 'file'
			title: f.name
			url: f._url
		.value()
