Search.provide 'studyUtil files', ({ user, classIds, mimes }) ->
	studyUtils = StudyUtils.find({
		userIds: user._id
		classId: (
			if classIds.length > 0 then { $in: classIds }
			else { $nin: classIds } # match all classes
		)
		fileIds: $ne: []
	}, {
		fields:
			classId: 1
			userIds: 1
			fileIds: 1
	}).fetch()

	Files.find(
		_id: $in:
			_(studyUtils)
				.pluck 'fileIds'
				.flatten()
				.value()
		mime: (
			if mimes.length > 0 then { $in: mimes }
			else { $nin: mimes } # match all mimes
		)
	).map (f) ->
		type: 'file'
		title: f.name
		url: f.url()
