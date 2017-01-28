@_ = lodash # Shortcut for lo-dash. Replaces underscore.

linkify = require('linkify-it')()
linkify.tlds require 'tlds'

###*
# Returns today as an Date object.
#
# @method today
# @return {Date} Date object of today.
###
Date.today = -> new Date().date()

###*
# Creates a new Date object with the given amount of days added.
#
# @method addDays
# @param {Number} days The amount of days to add.
# @return {Date} A Date object with the given amount of days added.
###
Date::addDays = (days) ->
	check days, Match.Integer
	d = new Date this
	d.setDate this.getDate() + days
	d

Date::date = -> new Date @getFullYear(), @getMonth(), @getDate()

whitespaceReg = /^\s*$/
###
# Static class containing helper methods.
#
# @class Helpers
# @static
###
class @Helpers
	###*
	# Returns the amount of days between the 2 given dates.
	#
	# @method daysRange
	# @param firstDate {Date} First date as a Date object.
	# @param lastDate {Date} Last date as a Date object.
	# @param useTime {Boolean} If true the calculation will consider the time of the given dates.
	# @param round {Boolean} Whether or not to round the result.
	# @return {Number} Amount of days between the two given dates. Can be negative.
	###
	@daysRange: (firstDate, lastDate, useTime = yes, round = yes) ->
		if useTime
			moment(lastDate).diff firstDate, "days", not round
		else
			# When not using time, the result is always rounded.
			moment(lastDate.date()).diff firstDate.date(), "days"

	###*
	# Returns the current day of the week.
	#
	# @method currentDay
	# @return {DayEnum} The current day of the week.
	###
	@currentDay: -> Helpers.weekDay new Date

	###*
	# Gets the weekday of the given `date`.
	# Where 0 = monday and 6 = sunday
	#
	# @method weekDay
	# @param date {Date} The Date object to get the weekday from.
	# @return {Number} The weekday of `date`.
	###
	@weekDay: (date) -> if (date.getDay() - 1) >= 0 then date.getDay() - 1 else DayEnum.sunday

	###*
	# Converts the given date to a ISO 8601 format as YYYYMMDD.
	#
	# @method dateToIso
	# @param date {Date} A date object to convert.
	# @return {String} A date as ISO 8601 format as YYYYMMDD.
	###
	@dateToIso: (date) -> date.getUTCFullYear() + Helpers.addZero(date.getUTCMonth() + 1) + Helpers.addZero(date.getUTCDate())

	###*
	# Converts the given string as ISO 8601 format as YYYYMMDD to a Date object.
	#
	# @method isoToDate
	# @param isoDate {String} A date as ISO 8601 format as YYYYMMDD to convert.
	# @return {Date} The given ISO date as a Date object.
	###
	@isoToDate: (isoDate) -> new Date isoDate[0...4], isoDate[4...6] - 1, isoDate[6...8]

	###*
	# Adds a zero in front of the original number if it doesn't yet.
	#
	# @method addZero
	# @param original {Number|String} The number to add a zero in front to.
	# @return {String} The number as string with a zero in front of it.
	###
	@addZero: (original) -> if +original < 10 then "0#{original}" else original.toString()

	###*
	# Checks if the given original string contains the given query string.
	#
	# @method contains
	# @param original {String} The original string to search in.
	# @param query {String} The string to search for.
	# @param ignoreCasing {Boolean} Whether to ignore the casing of the search.
	# @return {Boolean} Whether the original string contains the query string.
	###
	@contains: (original = '', query = '', ignoreCasing = false) ->
		if ignoreCasing
			original
				.toUpperCase()
				.indexOf(query.toUpperCase()) >= 0
		else
			original
				.indexOf(query) >= 0

	###*
	# Returns all the matches of the given RegEx tested on the given string as strings.
	#
	# @method allMatches
	# @param regex {Regexp} The RegEx to use.
	# @param str {String} The string to test the RegEx on.
	# @return {String[]} An array containing all the matches found as strings. (example: ["hoofdstuk 4", "hoofdstuk 10"])
	###
	@allMatches: (regex, str) ->
		# If no global flag is set there's only one result.
		# Without this the while loop will be an infinite loop.
		return [regex.exec(str)?[0]] unless regex.global

		tmp = []
		tmp.push item[0] while (item = regex.exec str)?
		tmp

	###*
	# Returns all the matches of the given RegEx tested on the given string with the details.
	#
	# @method allMatchesDetailed
	# @param regex {Regexp} The RegEx to use.
	# @param str {String} The string to test the RegEx on.
	# @return {RegExpResult[]} An array containing all the matches found. As an addition it also contains `lastIndex: number`
	###
	@allMatchesDetailed: (regex, str) ->
		# If no global flag is set there's only one result.
		# Without this the while loop will be an infinite loop.
		return [regex.exec(str)] unless regex.global

		tmp = []

		while (item = regex.exec str)? then tmp.push _.extend item, lastIndex: item.index + item[0].length

		tmp

	###*
	# Caps the given string.
	# @method cap
	# @param string {String} The string to cap.
	# @param [amount=1] {Number} The amount of characters from index 0 of `string` to cap.
	# @return {String} The capped `string`.
	###
	@cap: (string, amount = 1) -> string[0...amount].toUpperCase() + string[amount..].toLowerCase()

	###*
	# Caps the given string, respecting name conventions.
	# @method nameCap
	# @param name {String} The name to cap.
	# @return {String} The capped `name`.
	###
	@nameCap: (name) ->
		nonCapped = [
			'aan'
			'bij'
			'd'
			'de'
			'den'
			'der'
			'en'
			'het'
			'in'
			'in'
			'o'
			'of'
			'onder'
			'op'
			'over'
			's'
			't'
			'te'
			'ten'
			'ter'
			'tot'
			'uit'
			'uit'
			'van'
			'vanden'
			'vd'
			'voor'
		]

		name
			.trim()
			.toLowerCase()
			.replace /\w+/g, (match) =>
				if match in nonCapped then match else @cap match

	###*
	# Find links in the given `string` and converts
	# those into anchor tags.
	#
	# @method convertLinksToAnchor
	# @param {String} str The string to convert.
	# @return {String} An HTML string containing the converted `str`.
	###
	@convertLinksToAnchor: (str) ->
		matches = linkify.match str
		res = []
		last = 0

		for match in matches ? []
			res.push str.slice(last, match.index) if last < match.index
			res.push "<a target='_blank' href='#{match.url}'>#{match.text}</a>"
			last = match.lastIndex

		if last < str.length
			res.push str.slice last

		res.join ''

	###*
	# Sets an interval for the given `func`. While immediately executing it.
	# Optionally also binds to an object containing a stop function.
	#
	# @method interval
	# @param {Function} func
	# @param {Number} interval
	# @param {Boolean} [bind=true] Sets `this` to { stop: function()->void }
	# @return {Number}
	###
	@interval: (func, interval, bind = yes) ->
		if bind then func = _.bind func, stop: -> Meteor.clearInterval handle
		Meteor.defer func
		handle = Meteor.setInterval func, interval

	###*
	# Returns an array containing each day of the week starting on Monday.
	# Respects the current moment locale.
	#
	# @method weekdays
	# @return {String[]}
	###
	@weekdays: ->
		weekdays = moment()._locale._weekdays
		_(weekdays)
			.slice 1
			.push weekdays[0]
			.value()

	###
	# Returns the strength of the given `password`, Rules (and their weight)
	# stolen from http://www.passwordmeter.com/
	#
	# @method passwordStrength
	# @param {String} password The password to check
	# @return {Number} The strength of `password`.
	###
	@passwordStrength: (password) ->
		uppercaseChars = _.filter password, (c) -> c.toUpperCase() is c
		lowercaseChars = _.filter password, (c) -> c.toLowerCase() is c
		numbers = _.reject password, (c) -> isNaN c
		symbols = _.filter password, (c) -> /[-!$%^&*()_+|~=`{}\[\]:";'<>?,.\/]/.test c
		middleNumbersOrSymbols =
			_.filter numbers.concat(symbols), (c, i) -> 0 < i < password.length-1
		len = password.length

		sum = 0
		sum += len * 4
		sum += numbers.length * 4
		sum += symbols.length * 6
		sum += middleNumbersOrSymbols.length * 2
		sum += (len - uppercaseChars.length) * 2
		sum += (len - lowercaseChars.length) * 2
		sum

	###*
	# Checks if the given `mail` is a valid address.
	#
	# @method validMail
	# @param mail {String} The address to check.
	# @return {Boolean} True if the given mail is valid, otherwise false.
	###
	@validMail: (mail) -> /(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/i.test mail

	###*
	# Tests if the months and dates of the given two date objects are the same.
	#
	# @method datesEqual
	# @param a {Date}
	# @param b {Date}
	# @return {Boolean}
	###
	@datesEqual: (a, b) -> a.getMonth() is b.getMonth() and a.getDate() is b.getDate()

	###*
	# Changes `original` using the given `sedcommand`.
	# If no `original` is given: return whether or not the given `sedcomand` is a
	# valid sed command.
	#
	# @method sed
	# @param sedcommand {String}
	# @param [original] {String}
	# @return {String|Boolean}
	###
	@sed: (sedcommand, original) ->
		sedreg = /^s([^\s\w])([^\1]+?)\1([^\1]*?)(?:\1(|ig?|gi?))?$/
		res = sedreg.exec sedcommand

		if not original?
			return res?
		else if not res?
			return original

		matcher = res[2]
		replacer = res[3]
		flags = res[4]

		matchreg = new RegExp matcher, flags
		original.replace matchreg, replacer

	###*
	# Gets the first character from `str` utf-8 compound characters.
	# Returns an empty string if `str` is empty.
	#
	# @method first
	# @param {String} str
	# @return {String}
	###
	@first: (str) ->
		astralSymbols = /^[\uD800-\uDBFF][\uDC00-\uDFFF]/
		if astralSymbols.test str
			str.substr 0, 2
		else
			str[0] ? ''

	###*
	# Returns the given `date` friendly formatted.
	# If `date` is a null value, `undefined` will be returned.
	#
	# @method formatDate
	# @param {Date} date The date to format.
	# @param {Boolean} [prefixes=false]
	# @return {String|undefined} The given `date` formatted.
	###
	@formatDate: (date, prefixes = no) ->
		return undefined unless date?

		check date, Date
		check prefixes, Boolean
		m = moment date

		m.format (
			if m.year() isnt new Date().getFullYear()
				if prefixes
					'[op] DD-MM-YYYY [om] HH:mm'
				else
					'DD-MM-YYYY HH:mm'
			else if m.toDate().date().getTime() isnt Date.today().getTime()
				if prefixes
					'[op] DD-MM [om] HH:mm'
				else
					'DD-MM HH:mm'
			else
				if prefixes
					'[om] HH:mm'
				else
					'HH:mm'
		)

	###*
	# @method timeDiff
	# @param {Date|moment} a
	# @param {Date|moment} b
	# @return {String}
	###
	@timeDiff: (a, b) ->
		seconds = Math.abs moment(b).diff(a) / 1000

		minutes = Math.round seconds / 60
		if minutes < 1
			return 'minder dan 1 minuut'

		hours = Math.floor minutes / 60
		minutes -= hours * 60

		arr = []
		if hours isnt 0
			arr.push "#{hours}u"
		if minutes isnt 0
			arr.push "#{minutes}m"
		arr.join ' en '

	###*
	# @method formatDateRelative
	# @param {Date} date
	# @param {Boolean} [showTime=true]
	# @return {String}
	###
	@formatDateRelative: (date, showTime = yes) ->
		m = moment date

		day = m.format 'dddd'
		time = m.format 'HH:mm'
		sameYear = m.year() is moment().year()

		date = switch @daysRange new Date, date, no
			when -6, -5, -4, -3 then "afgelopen #{day}"
			when -2 then 'eergisteren'
			when -1 then 'gisteren'
			when 0 then 'vandaag'
			when 1 then 'morgen'
			when 2 then 'overmorgen'
			when 3, 4, 5, 6 then "aanstaande #{day}"
			else "#{day} #{DateToDutch date, not sameYear}"

		if showTime then "#{date} #{time}"
		else date

	###*
	# Emboxes the given function to only invalidate the current computation when
	# the return value is different from the previous one. (compared using
	# `EJSON.equals`)
	#
	# @method embox
	# @param {Funtion} fn
	# @param {Object} [thisArg=window]
	# @param {any[]} [args=[]]
	# @return {mixed}
	###
	@embox: (fn, thisArg = window, args = []) ->
		unless Tracker.currentComputation?
			return fn.apply thisArg, args

		val = new ReactiveVar

		Tracker.autorun ->
			newVal = fn.apply thisArg, args
			val.set newVal unless EJSON.equals val.curValue, newVal

		val.get()

	# REVIEW: better name for this function?
	###*
	# Checks if the string is null, empty or only contains whitespace.
	# Faster than `str.trim().length === 0`
	#
	# @method isEmptyString
	# @param {String} str
	# @return {Boolean}
	###
	@isEmptyString: (str) ->
		not str? or whitespaceReg.test str

	###*
	# @method oneLine
	# @param {String} str
	# @return {String}
	###
	@oneLine: (str) ->
		str.replace /(.)? *\n+/g, (match, char) ->
			s = char ? ''
			if char not in [ '.', ',', '!', '?', ';', ':' ]
				s += ';'
			"#{s} "

	###*
	# @method find
	# @param {Array|Object} coll
	# @param {Object} query
	# @return {any}
	###
	@find: (coll, query) ->
		matcher = createMatcher query
		_.find coll, (x) -> matcher x

	###*
	# @method filter
	# @param {Array|Object} coll
	# @param {Object} query
	# @return any
	###
	@filter: (coll, query) ->
		matcher = createMatcher query
		_.filter coll, (x) -> matcher x

###*
# @method getUserField
# @param {String} userId
# @param {String} field
# @param {mixed} [def] Optional default value to set the result to if it's undefined or null.
# @return {mixed}
###
@getUserField = (userId, field, def) ->
	check userId, Match.Maybe String
	check field, String
	check def, Match.Maybe Match.Any

	return def unless userId?
	user = Meteor.users.findOne userId, fields: "#{field.split('[')[0]}": 1
	_.get(user, field) ? def

###*
# Gets the date of the given `event` for the user with the given `userId`.
# @method getEvent
# @param {String} event
# @param {String} [userId=Meteor.userId()]
# @return {Date}
###
@getEvent = (event, userId = Meteor.userId()) -> getUserField userId, "events.#{event}"

###*
# Checks if the given `user` is in the given `roles`.
# @method userIsInRole
# @param userId {String} The ID of the user to check.
# @param [roles=["admin"]] {String|String[]} The role(s) to check.
# @return {Boolean} True if the given `user` is in the given `roles`.
###
@userIsInRole = (userId, roles = ['admin']) ->
	roles = if _.isArray(roles) then roles else [roles]
	userRoles = getUserField userId, 'roles', []
	_.every roles, (role) -> _.contains userRoles, role

###*
# Gets the course info for the user with the given id.
# @method getCourseInfo
# @param {String} userId
# @return {Object}
###
@getCourseInfo = (userId) -> getUserField userId, 'profile.courseInfo', {}

###*
# Gets the classInfo of the user with the given id.
# @method getClassInfos
# @param {String} [userId=Meteor.userId()]
# @return {Object[]}
###
@getClassInfos = (userId = Meteor.userId()) -> getUserField userId, 'classInfos', []

@getUserStatus = (userId) ->
	status = getUserField userId, 'status'
	if status?
		if status.idle then 'inactive'
		else if status.online then 'online'
		else 'offline'

###*
# @method getClassGroup
# @param {string} classId
# @param {String} [userId=Meteor.userId()]
# @return {String}
###
@getClassGroup = (classId, userId = Meteor.userId()) ->
	check classId, String
	check userId, String

	CalendarItems.findOne({
		classId: classId
		userIds: userId
	}, {
		sort:
			startDate: -1
	})?.group()

###*
# @method createMatcher
# @param {Object} query
# @param {Object} [options]
# @return {Function} Checks if the given object matches `query`
###
@createMatcher = (query, options) ->
	check query, Object
	check options, Match.Optional Object
	matcher = new Mongo.Cursor(undefined, query, options).matcher
	(obj) -> matcher._docMatcher(obj).result
