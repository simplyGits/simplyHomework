###*
# Enum that contains all the days of a week. Zero based.
#
# @property DayEnum
###
@DayEnum =
	monday: 0
	tuesday: 1
	wednesday: 2
	thursday: 3
	friday: 4
	saturday: 5
	sunday: 6

@dutchDays = [
	'maandag'
	'dinsdag'
	'woensdag'
	'donderdag'
	'vrijdag'
	'zaterdag'
	'zondag'
]

@DayToDutch = (day) ->
	unless day?
		minuteTracker?.depend()
		day = Helpers.currentDay()

	dutchDays[day]

###*
# @method DateToDutch
# @param {Date} [date]
# @param {Boolean} [includeYear=true]
###
@DateToDutch = (date, includeYear = yes) ->
	unless date?
		minuteTracker?.depend()
		date = new Date

	moment(date).format (
		fmt = 'D MMMM'
		fmt += ' YYYY' if includeYear
		fmt
	)

@TimeGreeting = (date) ->
	unless date?
		minuteTracker?.depend()
		date = new Date

	hour = date.getHours()
	if 0 <= hour < 6 then 'Goedenacht'
	else if 6 <= hour < 12 then 'Goedemorgen'
	else if 12 <= hour < 18 then 'Goedemiddag'
	else if 18 <= hour < 24 then 'Goedenavond'
