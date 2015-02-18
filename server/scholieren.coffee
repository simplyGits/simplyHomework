class @Scholieren
	@getClasses: ->
		options = _.find(arguments, (a) -> _.isObject a) ? { name: null, id: null }
		callback = _.find(arguments, (a) -> _.isFunction a)

		options.name = options.name ? undefined
		options.id = options.id ? undefined

		optionsKey = _(options).keys().find (k) -> options[k]?

		HTTP.post "http://api.scholieren.com/", {
			params:
				"client_id": "32c8014e0e49363bce563d940859dade"
				"client_pw": "a56c98c29403f35d7e6152caf12e5c5e"
				"request": "subjects"
				"by_item": optionsKey ? ""
				"by_data": options[optionsKey] ? ""

		}, (e, r) ->
			if e?
				callback(e, null)
			else
				callback null, JSON.parse(r.content).subjects

	@getBooks: ->
		options = _.find(arguments, (a) -> _.isObject a) ? { name: null, id: null, classId: null }
		callback = _.find(arguments, (a) -> _.isFunction a)

		options.name = options.name ? undefined
		options.id = options.id ? undefined
		options.classId = options.classId ? undefined

		optionsKey = _(options).keys().find (k) -> options[k]?

		HTTP.post "http://api.scholieren.com/", {
			params:
				"client_id": "32c8014e0e49363bce563d940859dade"
				"client_pw": "a56c98c29403f35d7e6152caf12e5c5e"
				"request": "methods"
				"by_item": optionsKey ? ""
				"by_data": options[optionsKey] ? ""

		}, (e, r) ->
			if e?
				callback(e, null)
			else
				callback null, (id: x.id, classId: x.vakid, title: x.name for x in JSON.parse(r.content).methods)
