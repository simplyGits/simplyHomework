###*
# Normalizes the given `variant`.
# @method normalizeSchoolVariant
# @param {String} variant
# @return {String}
###
@normalizeSchoolVariant = (variant) ->
	# TODO: extend this method.
	check variant, String
	variant = variant.toLowerCase().trim()
	switch variant
		when 'gymnasium', 'atheneum' then 'vwo'
		else variant

@normalizeClassName = (name) ->
	name = name.toLowerCase()
	contains = (s) -> _.contains name, s

	if contains 'nederlands'
		'Nederlands'
	else if contains 'frans'
		'Frans'
	else if contains 'duits'
		'Duits'
	else if contains 'engels'
		'Engels'
	else
		name

###*
# @class SchoolClass
# @constructor
# @param name {String}
# @param abbreviation {String}
# @param year {Number} The year of the class this class is in.
# @param schoolVariant {String} e.g VWO
###
class @SchoolClass
	constructor: (name, abbreviation, @year, schoolVariant) ->
		@name = Helpers.cap name if name?
		@schoolVariant = normalizeSchoolVariant schoolVariant
		abbreviation = abbreviation.toLowerCase().trim()

		###*
		# @property abbreviations
		# @type String[]
		###
		@abbreviations = []
		@abbreviations.push abbreviation unless _.isEmpty abbreviation

		@schedules = [] # Contains schedule ID's.

		###*
		# @property externalInfo
		# @type Object
		# @default {}
		###
		@externalInfo = {}
