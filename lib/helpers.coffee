root = @

@uS = _ 	 # We need underscore sometimes; refer uS to underscore
@_  = lodash # Shortcut for lo-dash. Replaces underscore.

###*
# Returns today as an Date object.
#
# @method today
# @return {Date} Date object of today.
###
Date.today = -> new Date().date()

###*
# Adds the given ammount of days to the current Date object.
#
# @method addDays
# @param days {Number} The amount of days to add.
# @return {Date} The current Date object with the given ammount of days added.
###
Date::addDays = (days, newDate = false) ->
	check days, Number
	newDate = false unless Match.test newDate, Boolean

	if newDate
		return new Date @getTime() + (86400000 * days)
	else
		@setDate @getDate() + days
		return @

Date::date = -> return new Date @getUTCFullYear(), @getMonth(), @getDate()

Array::remove = (item) ->
	if _.isObject(item) and _.contains _.keys(item), "_id"
		_.remove @, (i) -> EJSON.equals item._id, i._id
	else
		_.remove @, (i) -> EJSON.equals item, i

	return @
Array::smartFind = (item, loopMap) -> _.find @, (i) -> EJSON.equals((if _.isFunction(loopMap) then loopMap i else i), item)
Array::pushMore = (items) -> [].push.apply @, items; return @

###
# Static class containing helper methods.
#
# @class Helpers
###
class @Helpers
	###*
	# Returns the amount of days between the 2 given dates.
	#
	# @method daysRange
	# @param firstDate {Date} First date as a Date object.
	# @param lastDate {Date} Last date as a Date object.
	# @return {Number} Amount of days between the two given dates. Can be negative.
	###
	@daysRange: (firstDate, lastDate) -> return Math.round (lastDate.getTime() - firstDate.getTime()) / 86400000

	###*
	# Returns the current day of the week.
	#
	# @method currentDay
	# @return {DayEnum} The current day of the week.
	###
	@currentDay: -> Helpers.weekDay new Date

	@weekDay: (date) -> if (date.getDay() - 1) >= 0 then date.getDay() - 1 else DayEnum.Sunday

	###*
	# Converts the given date to a ISO 8601 format as YYYYMMDD.
	#
	# @method dateToIso
	# @param date {Date} A date object to convert.
	# @return {String} A date as ISO 8601 format as YYYYMMDD.
	###
	@dateToIso: (date) -> return date.getUTCFullYear() + Helpers.addZero(date.getUTCMonth() + 1) + Helpers.addZero(date.getUTCDate())

	###*
	# Converts the given string as ISO 8601 format as YYYYMMDD to a Date object.
	#
	# @method isoToDate
	# @param isoDate {String} A date as ISO 8601 format as YYYYMMDD to convert.
	# @return {Date} The given ISO date as a Date object.
	###
	@isoToDate: (isoDate) -> return new Date isoDate[0...4], isoDate[4...6] - 1, isoDate[6...8]

	###*
	# Adds a zero in front of the original number if it doesn't yet.
	#
	# @method addZero
	# @param original {Number} The number to add a zero in front to.
	# @return {String} The number as string with a zero in front of it.
	###
	@addZero: (original) -> return if original < 10 then "0#{original}" else original.toString()

	###*
	# Checks if the given original string contains the given query string.
	#
	# @method contains
	# @param original {String} The original string to search in.
	# @param query {String} The string to search for.
	# @param ignoreCasing {Boolean} Whether to ignore the casing of the search.
	# @return {Boolean} Whether the original string contains the query string.
	###
	@contains: (original, query, ignoreCasing = false) ->
		return if ignoreCasing then original.toUpperCase().indexOf(query.toUpperCase()) >= 0 else original.indexOf(query) >= 0

	###*
	# Returns all the matches of the given RegEx tested on the given string.
	#
	# @method allMatches
	# @param regex {Regexp} The RegEx to use.
	# @param str {String} The string to test the RegEx on.
	# @return {Array} An array containing all the matches found. (example: ["hoofdstuk 4", "hoofdstuk 10"])
	###
	@allMatches: (regex, str) ->
		tmp = []
		tmp.push item[0] while (item = regex.exec str) isnt null
		return tmp

	@getTotal: (arr, mapper) ->
		sum = 0
		sum += (if _.isFunction(mapper) then mapper i else i) for i in arr
		return sum

	###*
	# Returns the average of the values in the given array.
	#
	# @method getAverage
	# @param arr {Array} The array to get the average of.
	# @param mapper {Function} Optional. The function to map the values in the array to before counting it to the average.
	# @return {Number} The average of the given values.
	###
	@getAverage: (arr, mapper) -> return root.Helpers.getTotal(arr, mapper) / arr.length

	@cap: (string, amount = 1) -> string[0...amount].toUpperCase() + string[amount..].toLowerCase()

	@try: (func) ->
		try
			func()
			return yes
		catch
			return no

@userIsInRole = (user = Meteor.user(), role = "admin") ->
	if _.isString(user) then user = Meteor.users.findOne user
	return no unless user?
	_.every (if _.isArray(role) then role else [role]), (s) -> _.contains user.roles, s

###*
# Generates a getter/setter method for a global class variable.
#
# @param varName {String} The name of the variable to make method for.
# @param pattern {Pattern} The Match pattern to test when the variable is being changed.
# @param allowChanges {Boolean} Whether to allow changes to the property (otherwise it's just going to generate a getter method)
# @param transformIn {Function} Function to map the new variable to before saving it.
# @param transformOut {Function} Function to map the variable that gets returned to.
# @return {Function} A getter/setter method for the given global class variable.
###
@getset = (varName, pattern = Match.Any, allowChanges = yes, transformIn, transformOut) ->
	return (newVar) ->
		if newVar?
			if allowChanges
				@[varName] = if _.isFunction(transformIn) then transformIn newVar else newVar
			else
				throw new root.NotAllowedException "Changes on this property aren't allowed"
		return if _.isFunction(transformOut) then transformOut @[varName] else @[varName]