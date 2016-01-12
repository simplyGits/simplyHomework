placeholders = [
	'Samenvattingen voor %class%'
	'Woordenlijsten voor %class%'
	'%class% Powerpoint H1'
	'%class% Projecten'
	'Hendrik-Jan'
]
# fallback string for when the user's classes can't be loaded.
fallbackClass = _.sample [
	'Nederlands'
	'Engels'
]

cache = {}
_fetch = _.throttle ((query, callback) ->
	Meteor.apply 'search', [ query ],
		wait: no
		onResultReceived: (e, r) ->
			cache[query] = r
			callback? r ? []
), 150

fetch = (query, sync, callback) ->
	query = query.trim().toLowerCase()
	if (val = cache[query])?
		_fetch query
		sync? val
		val
	else
		_fetch query, callback
		undefined

route = (query, d) ->
	return unless d?
	if d.type is 'route' then FlowRouter.go d.path, d.params
	else if d.type is 'modal' then showModal d.id
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
		_.sample(placeholders).replace '%class%', ->
			c = _.sample classes().fetch()
			if c?
				if _.random(1) then c.name else c.abbreviations[0]
			else
				fallbackClass

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
