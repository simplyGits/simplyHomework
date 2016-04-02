variantMap =
	vwo: [
		'a'
		'v'
		'gm'
		'gym'
		'cygnus'
		'atheneum'
		'gymnasium'
	]
	havo: [
		'h'
	]

###*
# Normalizes the given `variant`.
# @method normalizeSchoolVariant
# @param {String} [variant='']
# @return {String}
###
@normalizeSchoolVariant = (variant = '') ->
	check variant, String
	variant = variant.toLowerCase().trim()

	for [ type, items ] in _.pairs variantMap
		if variant is type or variant in items
			return type

	variant

@normalizeClassName = (name) ->
	name = name.toLowerCase()
	contains = (s) -> _.contains name, s
	equals = (s) -> name is s
	startsWith = (s) -> name.indexOf(s) is 0

	if contains 'nederlands'
		'Nederlands'
	else if contains 'frans'
		'Frans'
	else if contains 'duits'
		'Duits'
	else if contains 'engels'
		'Engels'
	else if contains('rekentoets') or contains('rekenen')
		'Rekenen'
	else if equals('gym') or equals('sport en beweging')
		'Lichamelijke opvoeding'
	else if equals('anw') or equals('alg.nat.wet') or equals('alg. natuurwetenschappen')
		'Algemene natuurwetenschappen'
	else if equals 'ckv'
		'Culturele en kunstzinnige vorming'
	else if equals('kcv') or startsWith('klassieke cult')
		'Klassieke culturele vorming'
	else if startsWith 'levensbesch'
		'Levensbeschouwing'
	else if contains 'mentoruur'
		'Mentoruur'
	else if contains 'spaans'
		'Spaans'
	else if startsWith 'management en org'
		'Management en organisatie'
	else
		name

classTransform = (c) ->
	return c if Meteor.isServer
	classInfo = _.find getClassInfos(), (info) -> EJSON.equals info.id, c._id

	_.extend c,
		#__taskAmount: _.filter(homeworkItems.get(), (a) -> groupInfo?.group is a.description() and not a.isDone()).length
		__book: -> Books.findOne classInfo?.bookId
		__sidebarName: (
			val = c.name
			if val.length > 14 then c.abbreviations[0]
			else val
		)

		__color: classInfo?.color
		__classInfo: classInfo

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
		@name = Helpers.cap normalizeClassName name
		@schoolVariant = normalizeSchoolVariant schoolVariant
		abbreviation = abbreviation.toLowerCase().trim()

		###*
		# @property abbreviations
		# @type String[]
		###
		@abbreviations = []
		@abbreviations.push abbreviation unless _.isEmpty abbreviation

		###*
		# @property externalInfo
		# @type Object
		# @default {}
		###
		@externalInfo = {}

	@schema: new SimpleSchema
		name:
			type: String
			label: 'Vaknaam'
			trim: yes
			regEx: /^[A-Z][^A-Z]+$/
		abbreviations:
			type: [String]
			label: 'Vakafkortingen'
		year:
			type: Number
		schoolVariant:
			type: String
			regEx: /^[a-z]+$/
		externalInfo:
			type: Object
			blackbox: yes

@Classes = new Mongo.Collection 'classes', transform: (c) -> classTransform c
@Classes.attachSchema SchoolClass.schema
