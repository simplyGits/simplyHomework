Search.provide 'routes', ->
	[
		[ 'Agenda', 'calendar' ]
		[ 'Berichten', 'messages' ]
		[ 'Instellingen', 'settings' ]
	].map ([ name, path, params ], i) ->
		_id: i
		type: 'route'
		title: name
		path: path
		params: params
