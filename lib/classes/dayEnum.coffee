root = @

###*
# Enum that contains all the days of a week. Zero based.
#
# @property DayEnum
###
@DayEnum =
	Monday: 0
	Tuesday: 1
	Wednesday: 2
	Thursday: 3
	Friday: 4
	Saturday: 5
	Sunday: 6

@dutchDays = [
	"maandag"
	"dinsdag"
	"woensdag"
	"donderdag"
	"vrijdag"
	"zaterdag"
	"zondag"
]

@DayToDutch = (day = Helpers.currentDay()) ->
	secondTracker.depend()
	dutchDays[day]

@DateToDutch = (date = new Date, includeYear = yes) ->
	secondTracker.depend()
	month = switch date.getMonth()
		when 0 then "januari"
		when 1 then "februari"
		when 2 then "maart"
		when 3 then "april"
		when 4 then "mei"
		when 5 then "juni"
		when 6 then "juli"
		when 7 then "augustus"
		when 8 then "september"
		when 9 then "oktober"
		when 10 then "november"
		when 11 then "december"

	return if includeYear then "#{date.getDate()} #{month} #{date.getFullYear()}" else "#{date.getDate()} #{month}"