CACHE_TIMEOUT = ms.minutes 10

# improve placeholders

placeholders = [
	'Samenvattingen voor %class%'
	'Woordenlijsten voor %class%'
	'%class% Projecten'
	'%class% Powerpoint H%num%'
	'samenvatting %class% H%num%'
	'%class% project H%num%'
	'%name%'
]
fallbackClasses = [
	'Nederlands'
	'Engels'
	'Wiskunde'
	'Lichamelijke opvoeding'
]
fallbackNames = [
	'Piet'
	'Piet Jansen'
	'Maria'
	'Isaac'
	'Josephine'
]

getClassName = ->
	currentLesson = Helpers.embox ScheduleFunctions.currentLesson
	c = (
		if currentLesson?
			currentLesson.class()
		else
			_.sample classes().fetch()
	)
	if c?
		if _.random(1) then c.name else c.abbreviations[0]
	else
		_.sample fallbackClasses

getName = ->
	user = _.sample Meteor.users.find({
		_id: $ne: Meteor.userId()
		'profile.firstName': $ne: ''
	}, {
		fields:
			_id: 1
			'profile.firstName': 1
			'profile.lastName': 1
		transform: null
	}).fetch()

	if user?
		s = user.profile.firstName
		s += " #{user.profile.lastName}" if _.random 1
		s
	else
		_.sample fallbackNames

cache = {}
_fetch = _.throttle ((query, callback) ->
	Meteor.apply 'search', [ query ],
		wait: no
		onResultReceived: (e, r) ->
			cache[query] =
				items: r
				time: _.now()
			callback? r ? []
), 150

fetch = (query, sync, callback) ->
	query = query.trim().toLowerCase()

	info = cache[query]
	if info?.items?
		if _.now()-info.time > CACHE_TIMEOUT
			_fetch query

		sync? info.items
		info.items
	else
		_fetch query, callback
		undefined

route = (query, d) ->
	$('#searchBar input').val('').blur()
	if d?
		if d.type is 'route'
			FlowRouter.go d.path, d.params
		else if d.type is 'modal'
			showModal d.id
		else if d.type in [ 'report', 'wordlist', 'file' ]
			window.open d.url, '_blank'
		else if d.type is 'message'
			FlowRouter.go 'messages', folder: d.folder, message: d._id
		else
			FlowRouter.go (
				switch d.type
					when 'user' then 'personView'
					when 'project' then 'projectView'
					when 'class' then 'classView'
			), id: d._id

		Meteor.call 'search.analytics.store', query, d._id

Template.searchBar.helpers
	placeholder: ->
		_.sample(placeholders)
			.replace '%class%', getClassName
			.replace '%num%', _.random 1, 15
			.replace '%name%', getName

Template.searchBar.events
	'keyup input': (event) ->
		query = event.target.value
		switch event.which
			when 13 then route query, fetch(query)?[0]
			when 27 then event.target.blur()

Template.searchBar.onRendered ->
	val = undefined
	@$('input')
		.typeahead {
			minLength: 2
			highlight: true
		}, {
			source: fetch
			async: yes
			name: 'general-search'
			limit: 7
			display: 'title'
			templates:
				suggestion: (d) -> Blaze.toHTMLWithData Template.searchSuggestion, d
		}
		.keypress (e) -> val = e.target.value + String.fromCharCode e.which
		.on 'typeahead:select', (event, d) -> route val, d

Template.searchSuggestion.helpers
	boxStyles: ->
		switch @type
			when 'user'
				"background-image: url('#{picture this, 100}')"
			when 'class'
				"background-color: #{Classes.findOne(@_id).__classInfo.color}"
