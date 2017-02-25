import shitdown from 'meteor/shitdown'

# Always keep this middleware on top, please.
ChatMiddlewares.attach 'preserve original content', 'client', (message) ->
	message._originalContent = message.content
	message.content = message.compiledContent
	message

###
ChatMiddlewares.attach 'shitdown', 'client', (message) ->
	message.content = shitdown message.content, [ 'code' ]
	message
###

genImage = (path) ->
	"<img class='emojione' style='height: 4ex' src='#{path}'></img>"

chatReplacements = [
	[[ '(y)'                ], ':thumbsup:'                               ]
	[[ '(n)'                ], ':thumbsdown:'                             ]
	[[ '(a)'                ], ':innocent:'                               ]
	[[ '(h)'                ], ':sunglasses:'                             ]
	[[ '^^\''               ], ':sweat_smile:'                            ]
	[[ ':fissa:', ':hype:'  ], ':tada:'                                   ]
	[[ ':kaas:'             ], ':cheese:'                                 ]
	[[ ':fu:'               ], ':middle_finger:'                          ]
	[[ ':sneeuwpop:'        ], _.sample [ ':snowman:', ':snowman2:' ]     ]
	[[ '/shrug/', ':shrug:' ], '¯\\_(ツ)_/¯'                              ]
	[[ ':kappa:'            ], genImage '/packages/chat/images/kappa.png' ]
	[[ '\\o/'               ], ':dancer:'                                 ]
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

###
ChatMiddlewares.attach 'shitdown code blocks', 'client', (message) ->
	message.content = shitdown.one message.content, 'code'
	message
###

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

ChatMiddlewares.attach 'add hidden fields', 'client', (cm) ->
	own = Meteor.userId() is cm.creatorId
	_.extend cm,
		__sender: Meteor.users.findOne cm.creatorId
		__own: if own then 'own' else ''
		__new: if own or Meteor.userId() in cm.readBy then '' else 'new'
		__time: Helpers.formatDate cm.time
		__changedOn: (
			date = cm.lastChange()?.date
			Helpers.formatDate date, yes
		)
		__pending: if cm.pending then 'pending' else ''
		__readBy: ->
			Meteor.users.find {
				_id:
					$in: cm.readBy
					$nin: [ Meteor.userId(), cm.creatorId ]
			}, {
				limit: 3
				sort:
					'profile.firstName': 1
			}
