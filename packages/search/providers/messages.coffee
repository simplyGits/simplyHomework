Search.provide 'messages', ({ user, classIds }) ->
	if classIds.length > 0 then []
	else
		Messages.find({
			fetchedFor: user._id
		}, {
			fields:
				_id: 1
				fetchedFor: 1
				subject: 1
				folder: 1

			transform: (m) ->
				type: 'message'
				_id: m._id
				title: m.subject
				folder: m.folder
		}).fetch()
