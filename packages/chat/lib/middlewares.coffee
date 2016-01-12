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

		for item in _.filter(@_middlewares, { platform })
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

chatMessageReplaceMap =
	':thumbsup:': /\(y\)/ig
	':thumbsdown:': /\(n\)/ig
	':innocent:': /\(a\)/ig
	':sunglasses:': /\(h\)/ig
	':sweat_smile:': /\^\^'/ig
	':tada:': /:(fissa|hype):/ig
	':cheese:': /:kaas:/ig
	':middle_finger:': /:fu:/ig
	'¯\\\\\\_(ツ)\\_/¯': /(:|\/)shrug(:|\/)/ig

ChatMiddlewares.attach 'convert smileys', 'client', (message) ->
	s = message.content

	for key of chatMessageReplaceMap
		regex = chatMessageReplaceMap[key]
		s = s.replace regex, key

	message.content = s
	message

ChatMiddlewares.attach 'emojione', 'client', (message) ->
	unless localStorage['no-chat-emojis']
		message.content = emojione.toImage message.content
	message

ChatMiddlewares.attach 'markdown', 'client', (message) ->
	message.content = marked message.content
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

ChatMiddlewares.attach 'strip naughty urls', 'insert', (message) ->
	message.content = message.content.replace(
		/<a +href *= *('|"?) *javascript *:[^\1]+\1 *>([^<]*)(<\/a>)?/ig
		(match, qoute, content) -> content
	)
	message

ChatMiddlewares.attach 'clickable names', 'insert', (message) ->
	schoolId = Meteor.user().profile.schoolId
	users = _(message.content)
		.split /\W/
		.map (word) -> Helpers.nameCap word
		.map (word, i) ->
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

@ChatMiddlewares = ChatMiddlewares
