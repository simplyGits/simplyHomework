###*
# @class Privacy
# @static
###
Privacy = {}

###*
# @property options
# @type Object[]
###
Privacy.options = [
	{
		description: 'Anderen toestaan je rooster te bekijken.'
		short: 'publishCalendarItems'
		default: yes
	}
	{
		description: 'Anderen toestaan je status te zien.'
		short: 'publishStatus'
		default: yes
	}
]

###*
# Gets the privacy options for the given `user`, with default values if an
# option hasn't been set yet.
#
# @method getOptions
# @param {String} userId
# @return {Object}
###
Privacy.getOptions = (userId) ->
	options = Meteor.users.findOne(
		{ _id: userId }
		{ fields: 'privacyOptions': 1 }
	)?.privacyOptions ? {}

	defaults = _.chain(Privacy.options)
		.map (obj) -> [ obj.short, obj.default ]
		.object()
		.value()

	_.defaults options, defaults

@Privacy = Privacy
