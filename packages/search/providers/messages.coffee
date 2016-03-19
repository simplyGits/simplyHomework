Search.provide 'messages', ({ user, classIds, mimes, query }) ->
	if classIds.length > 0 then [] # REVIEW: filter on messages from/to the teacher of the class?
	else
		messages = Messages.find({
			fetchedFor: user._id
		}, {
			fields:
				_id: 1
				fetchedFor: 1
				subject: 1
				folder: 1
				attachmentIds: 1

			sort:
				sendDate: -1
			limit: 20
		}).fetch()

		files = getFiles(
			_(messages)
				.pluck 'attachmentIds'
				.flatten()
				.value()
			mimes
		)

		files.concat messages.map (m) ->
			type: 'message'
			_id: m._id
			title: m.subject
			folder: m.folder
