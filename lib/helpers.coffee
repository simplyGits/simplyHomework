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
Array::pushMore = (items) -> [].push.apply @, items; return @

###*
# Checks if the given `mail` is a valid address.
# @method correctMail
# @param mail {String} The address to check.
# @return {Boolean} True if the given mail is valid, otherwise false.
###
@correctMail = (mail) -> /(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/i.test mail

###*
# Converts a grade to a number, can be Dutch grade style or English. More can be added.
# If the `grade` can't be converted it will return NaN.
#
# @method gradeConverter
# @param grade {String|Number} The grade to convert.
# @return {Number} `grade` converted to a number. Defaults to NaN.
###
@gradeConverter = (grade) ->
	return grade if _.isNumber grade
	# Normal dutch grades
	val = grade.replace(",", ".").replace(/[^\d\.]/g, "")
	unless val.length is 0 or _.isNaN(+val)
		return +val

	# English grades
	englishGradeMap =
		"F": 1.7
		"E": 3.3
		"D": 5.0
		"C": 6.7
		"B": 8.3
		"A": 10.0

	if _(englishGradeMap).keys().contains(grade.toUpperCase())
		return englishGradeMap[grade.toUpperCase()]

	return NaN

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
	# @param original {Number|String} The number to add a zero in front to.
	# @return {String} The number as string with a zero in front of it.
	###
	@addZero: (original) -> return if +original < 10 then "0#{original}" else original.toString()

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
		return tmp

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

		return tmp

	###*
	# Returns the sum of the values in the given array.
	#
	# @method getTotal
	# @param arr {Array} The array to get the sum of.
	# @param mapper {Function} Optional. The function to map the values in the array to before counting it to the sum.
	# @return {Number} The sum of the given values.
	###
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
	@getAverage: (arr, mapper) -> return @getTotal(arr, mapper) / arr.length

	###*
	# Caps the given string.
	# @method cap
	# @param string {String} The string to cap.
	# @param [amount=1] {Number} The amount of characters from index 0 of `string` to cap.
	###
	@cap: (string, amount = 1) -> string[0...amount].toUpperCase() + string[amount..].toLowerCase()

###*
# Checks if the given `user` is in the given `role`.
# @method userIsInRole
# @param [user=Meteor.user()] {User} The user to check.
# @param [role="admin"] {String} The role to check.
# @return {Boolean} True if the given `user` is in the given `role`.
###
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
