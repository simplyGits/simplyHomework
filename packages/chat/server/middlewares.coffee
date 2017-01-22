ChatMiddlewares.attach 'create compiledContent field', 'server', (message) ->
	message.compiledContent = message.content
	message

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

# TODO: improve 'clickable {names,classes}' middlewares

ChatMiddlewares.attach 'clickable names', 'server', (message) ->
	# REVIEW: maybe add a custom parser, which walks over every word. This way we
	# have more control over the matching and can we maybe support surnames
	# containing non-word characters.

	schoolId = getUserField message.creatorId, 'profile.schoolId'
	unless schoolId?
		return message

	choosen = []
	users = _(message.content)
		.split /\W/
		.map (word) -> Helpers.nameCap word
		.map (word) ->
			users = Meteor.users.find({
				$or: [
					{ 'profile.firstName': $ne: '', $eq: word }
					{ 'profile.lastName': $ne: '', $eq: word }
				]
				'profile.schoolId': schoolId
			}, {
				fields:
					_id: 1
					'profile.firstName': 1
					'profile.lastName': 1
					'profile.schoolId': 1
			}).fetch()

			user = (
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
	{ year, schoolVariant } = getCourseInfo message.creatorId

	classes = _(message.content)
		.split ' '
		.map (word) ->
			Classes.findOne
				$or: (
					x = [ name: $regex: "\\b#{_.escapeRegExp word}\\b", $options: 'i' ]
					if word is word.toUpperCase()
						x.push abbreviations: word.toLowerCase()
					x
				)
				schoolVariant: schoolVariant
				year: year
		.compact()
		.filter (c) ->
			classInfos = getClassInfos message.creatorId
			_.any classInfos, id: c._id
		.uniq '_id'
		.value()

	for c in classes
		regex = new RegExp "\\b((#{c.name})|#{c.abbreviations.join '|'})\\b", 'ig'
		message.compiledContent = message.compiledContent.replace regex, (str) ->
			path = FlowRouter.path 'classView', id: c._id
			"<a href='#{path}' class='class'>#{str}</a>"

	message
