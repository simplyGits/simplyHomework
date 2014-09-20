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

@DayToDutch = (day = Helpers.currentDay()) -> switch day
	when 0 then "maandag"
	when 1 then "dinsdag"
	when 2 then "woensdag"
	when 3 then "donderdag"
	when 4 then "vrijdag"
	when 5 then "zaterdag"
	when 6 then "zondag"

@DateToDutch = (date = new Date, includeYear = yes) ->
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