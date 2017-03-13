import katex from 'meteor/simply:katex'

escapeMap = [
	[ /</g, '&lt;' ]
	[ />/g, '&gt;' ]
]

ChatMiddlewares.attach 'escape', 'server', (message) ->
	s = message.compiledContent

	for [ reg, val ] in escapeMap
		s = s.replace reg, val

	message.compiledContent = s
	message

ChatMiddlewares.attach 'katex', 'server', (message) ->
	message.compiledContent = message.content.replace /\$\$(.+?)\$\$/g, (match, formula) ->
		try
			rendered = katex.renderToString formula
			rendered.replace /^<span/, '$& data-snap-ignore="true" '
		catch
			match

	message

# TODO: improve 'clickable {names,classes}' middlewares

ChatMiddlewares.attach 'clickable names', 'server', (message) ->
	# REVIEW: maybe add a custom parser, which walks over every word. This way we
	# have more control over the matching and can we maybe support surnames
	# containing non-word characters.

	schoolId = getUserField message.creatorId, 'profile.schoolId'
	unless schoolId?
		return message

	# TODO: make name matching case insensitive instead of using `Helpers.nameCap`

	words = _.chain(message.content)
		.split /\W/
		# FIXME: We just have isSurname=true for now ¯\_(ツ)_/¯
		.map (word) -> Helpers.nameCap word, yes
		.value()

	allUsers = Meteor.users.find({
		$or: [
			{ 'profile.firstName': $ne: '', $in: words }
			{ 'profile.lastName': $ne: '', $in: words }
		]
		'profile.schoolId': schoolId
	}, {
		fields:
			_id: 1
			'profile.firstName': 1
			'profile.lastName': 1
			'profile.schoolId': 1
	}).fetch()

	choosen = []
	users = _(words)
		.map (word) ->
			user = (
				users = _.filter allUsers, (u) ->
					{ firstName, lastName } = u.profile
					word in [ firstName, lastName ]

				# Try to find a user we already found earlier, prioritizing last. This
				# is used so that people with the same surname doesn't get wierdly
				# mangled or something. for example:
				# {Thomas [Konings]}
				# {} = 'Thomas Konings'
				# [] = 'Wouter Konings'
				(
					_(choosen)
						.map (userId) -> _.find users, _id: userId
						.compact()
						.last()
				) ?

				# If nobody has been found, try to find somebody else other than the
				# creator of the message
				_.find(users, (u) -> u._id isnt message.creatorId) ?

				# If nobody has been found, just take the first user
				users[0]
			)
			choosen.push user._id if user?
			user
		.compact()
		.uniq '_id'
		.value()

	for user in users
		{ firstName, lastName } = user.profile
		regex = new RegExp "@?(#{firstName} #{lastName}|#{firstName}|#{lastName})", 'ig'
		message.compiledContent = message.compiledContent.replace regex, (str) ->
			path = FlowRouter.path 'personView', id: user._id
			"<a href='#{path}' class='name'>#{str}</a>"

	message

ChatMiddlewares.attach 'clickable classes', 'server', (message) ->
	creator = Meteor.users.findOne {
		_id: message.creatorId
	}, {
		fields:
			'profile.courseInfo': 1
			'classInfos': 1
	}
	classInfos = creator.classInfos
	{ year, schoolVariant } = creator.profile.courseInfo

	words = message.content.split /\W/

	allClasses = Classes.find(
		schoolVariant: schoolVariant
		year: year
	).fetch()

	classes = _(words)
		.map (word) ->
			Helpers.find allClasses,
				$or: (
					x = [ name: $regex: "\\b#{_.escapeRegExp word}\\b", $options: 'i' ]
					if word is word.toUpperCase()
						x.push abbreviations: word.toLowerCase()
					x
				)
		.compact()
		.filter (c) -> _.any classInfos, id: c._id
		.uniq '_id'
		.value()

	for c in classes
		regex = new RegExp "\\b((#{c.name})|#{c.abbreviations.join '|'})\\b", 'ig'
		message.compiledContent = message.compiledContent.replace regex, (str) ->
			path = FlowRouter.path 'classView', id: c._id
			"<a href='#{path}' class='class'>#{str}</a>"

	message
