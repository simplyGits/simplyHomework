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
		delete c.fetchedBy
		c.externalInfo = {}

		containsName = (str) -> Helpers.contains str, c.name, yes

		scholierenClass = ScholierenClasses.findOne -> containsName @name
		if scholierenClass?
			c.externalInfo['scholieren'] = id: scholierenClass.scholierenId

		woordjesLerenClass = WoordjesLerenClasses.findOne -> containsName @name
		if woordjesLerenClass?
			c.externalInfo['woordjesLeren'] = id: woordjesLerenClass.woordjesLerenId

		Classes.insert c
