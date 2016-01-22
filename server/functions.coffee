###*
# @method insertClass
# @param {Class} class
# @return {String} The ID of the newely inserted class.
###
@insertClass = (c) ->
	old = Classes.findOne
		$or: [
			{ name: $regex: c.name, $options: 'i' }
			{ abbreviations: c.abbreviations }
		]
		schoolVariant: c.schoolVariant
		year: c.year

	if old?
		old._id
	else
		c.externalInfo = {}

		containsName = (str) ->
			a = Helpers.contains str, c.name, yes
			b = Helpers.contains c.name, str, yes
			a or b

		scholierenClass = _.find ScholierenClasses.find({}).fetch(), (c) -> containsName c.name
		if scholierenClass?
			c.externalInfo['scholieren'] = id: scholierenClass.id

		woordjesLerenClass = _.find WoordjesLerenClasses.find({}).fetch(), (c) -> containsName c.name
		if woordjesLerenClass?
			c.externalInfo['woordjesleren'] = id: woordjesLerenClass.id

		Classes.insert c
