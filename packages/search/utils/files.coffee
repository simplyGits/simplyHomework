@getFiles = (ids, mimes) ->
	Files.find({
		_id: $in: ids
		mime: (
			if mimes.length > 0 then { $in: mimes }
			else { $nin: mimes } # match all mimes
		)
	}, {
		fields:
			_id: 1
			name: 1
			mime: 1
	}).map (f) ->
		type: 'file'
		title: f.name
		url: f.url()
		weight: (
			if mimes.length > 0 then 5
			else 0
		)
