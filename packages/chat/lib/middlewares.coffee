###*
# @class ChatMiddlewares
# @static
###
ChatMiddlewares =
	_middlewares: []
	###*
	# Attaches a middleware. Order sensetive.
	#
	# @method attach
	# @param {String} name
	# @param {String} platform
	# @param {String} fn
	###
	attach: (name, platform, fn) ->
		check name, String
		check platform, String
		check fn, Function

		item = { name, platform, fn }

		@_middlewares.push item

	###*
	# Runs the given `message` through every middleware in order.
	# @method run
	# @param {ChatMessage} message
	# @param {String} [platform] The platform to run the middlewares for, if none is given one will automatically be chosen.
	# @return {ChatMessage}
	###
	run: (message, platform) ->
		platform ?= if Meteor.isClient then 'client' else 'server'

		for item in @_middlewares when item.platform is platform
			try
				message = item.fn message
			catch e
				console.warn "Message middleware '#{item.name}' errored.", e
				Kadira.trackError 'middleware-failure', e.toString(), stacks: JSON.stringify e

		message

# Always keep this middleware on top, please.
ChatMiddlewares.attach 'preserve original content', 'client', (message) ->
	message._originalContent = message.content
	message

ChatMiddlewares.attach 'shitdown', 'client', (message) ->
	message.content = shitdown message.content, [ 'code' ]
	message

chatReplacements = [
	[[ '(y)'                ], ':thumbsup:'      ]
	[[ '(n)'                ], ':thumbsdown:'    ]
	[[ '(a)'                ], ':innocent:'      ]
	[[ '(h)'                ], ':sunglasses:'    ]
	[[ '^^'                 ], ':sweat_smile:'   ]
	[[ ':fissa:', ':hype:'  ], ':tada:'          ]
	[[ ':kaas:'             ], ':cheese:'        ]
	[[ ':fu:'               ], ':middle_finger:' ]
	[[ '/shrug/', ':shrug:' ], '¯\\_(ツ)_/¯'     ]
].map ([ keys, value ]) ->
	regexp = new RegExp(
		"#{keys.map(_.escapeRegExp).join '|'}"
		'gi'
	)
	[ regexp, value ]

ChatMiddlewares.attach 'convert smileys', 'client', (message) ->
	unless getUserField Meteor.userId(), 'settings.devSettings.noChatEmojis'
		s = message.content
		res = ''
		cursor = 0

		while cursor < s.length
			idx = s.indexOf '`', cursor
			idx = s.length if idx is -1
			sl = s.slice cursor, idx

			for [ regexp, value ] in chatReplacements
				sl = sl.replace regexp, value

			res += sl

			cursor = 1 + s.indexOf '`', idx + 1
			cursor = s.length if cursor is 0

			res += s.slice idx, cursor

		message.content = res
	message

ChatMiddlewares.attach 'shitdown code blocks', 'client', (message) ->
	message.content = shitdown.one message.content, 'code'
	message

ChatMiddlewares.attach 'links', 'client', (message) ->
	s = message.content
	res = ''
	cursor = 0

	while cursor < s.length
		idx = s.indexOf '<code>', cursor
		idx = s.length if idx is -1

		res += Helpers.convertLinksToAnchor s.slice cursor, idx
		break if idx is s.length

		idx2 = s.indexOf '</code>', idx + 6
		idx2 = s.length if idx2 is -1

		res += s.slice idx, idx2
		cursor = idx2 + 7

	message.content = res
	message

ChatMiddlewares.attach 'emojione', 'client', (message) ->
	unless getUserField Meteor.userId(), 'settings.devSettings.noChatEmojis'
		message.content = emojione.toImage message.content
	message

ChatMiddlewares.attach 'katex', 'client', (message) ->
	message.content = message.content.replace /\$\$(.+)\$\$/, (match, formula) ->
		try katex.renderToString formula
		catch then match

	message

ChatMiddlewares.attach 'add hidden fields', 'client', (cm) ->
	own = Meteor.userId() is cm.creatorId
	_.extend cm,
		__sender: Meteor.users.findOne cm.creatorId
		__own: if own then 'own' else ''
		__new: if own or Meteor.userId() in cm.readBy then '' else 'new'
		__time: Helpers.formatDate cm.time
		__changedOn: Helpers.formatDate cm.changedOn
		__pending: if cm.pending then 'pending' else ''
		__readBy: ->
			Meteor.users.find {
				_id:
					$in: cm.readBy
					$nin: [ Meteor.userId(), cm.creatorId ]
			}, {
				limit: 3
			}

escapeMap = [
	[ /</g, '&lt;' ]
	[ />/g, '&gt;' ]
]

ChatMiddlewares.attach 'escape', 'insert', (message) ->
	s = message.content

	for [ reg, val ] in escapeMap
		s = s.replace reg, val

	message.content = s
	message

ChatMiddlewares.attach 'clickable names', 'insert', (message) ->
	schoolId = Meteor.user().profile.schoolId
	users = _(message.content)
		.split /\W/
		.map (word) -> Helpers.nameCap word
		.map (word) ->
			Meteor.users.findOne {
				_id: $nin: [ Meteor.userId(), message.creatorId ]
				$or: [
					{ 'profile.firstName': word }
					{ 'profile.lastName': word }
				]
				'profile.firstName': $ne: ''
				'profile.schoolId': schoolId
			}, {
				fields:
					_id: 1
					'profile.firstName': 1
					'profile.lastName': 1
					'profile.schoolId': 1
			}
		.compact()
		.uniq '_id'
		.value()

	for user in users
		{ firstName, lastName } = user.profile
		regex = new RegExp "@?(#{firstName} #{lastName}|#{firstName}|#{lastName})", 'ig'
		message.content = message.content.replace regex, (str) ->
			path = FlowRouter.path 'personView', id: user._id
			"<a href='#{path}' class='name'>#{str}</a>"

	message

ChatMiddlewares.attach 'clickable classes', 'insert', (message) ->
	{ year, schoolVariant } = getCourseInfo Meteor.userId()

	classes = _(message.content)
		.split ' '
		.map (word) ->
			Classes.findOne
				$or: [
					{ name: $regex: "\\b#{_.escapeRegExp word}\\b", $options: 'i' }
					{ abbreviations: word.toLowerCase() }
				]
				schoolVariant: schoolVariant
				year: year
		.filter (c) ->
			classInfos = getClassInfos message.creatorId
			_.any classInfos, id: c._id
		.compact()
		.uniq '_id'
		.value()

	for c in classes
		regex = new RegExp "(#{c.name})|(#{c.abbreviations.join '|'})", 'ig'
		message.content = message.content.replace regex, (str) ->
			path = FlowRouter.path 'classView', id: c._id
			"<a href='#{path}' class='class'>#{str}</a>"

	message

@ChatMiddlewares = ChatMiddlewares
