infos = [
	[/volgende (\w+) les/i, 1, "lesson", 1]
	[/volgende les (\w+)/i, 1, "lesson", 1]
	[/(\w+) volgende les/i, 1, "lesson", 1]

	[/vorige (\w+) les/i, -1, "lesson", 1]
	[/vorige les (\w+)/i, -1, "lesson", 1]
	[/(\w+) vorige les/i, -1, "lesson", 1]

	[/(\w+) eergister(en)?/i, "yesterday--", "lesson", 1]
	[/(\w+) gister(en)?/i, "yesterday", "lesson", 1]
	[/(\w+) morgen/i, "tomorrow", "lesson", 1]
	[/(\w+) overmorgen/i, "tomorrow++", "lesson", 1]

	[/eergister(en)?/i, -2, "days"]
	[/gister(en)?/i, -1, "days"]
	[/vandaag/i, 0, "days"]
	[/morgen/i, 1, "days"]
	[/overmorgen/i, 2, "days"]

	[/(\w+) maandag/i, "maandag", "lesson", 1]
	[/(\w+) dinsdag/i, "dinsdag", "lesson", 1]
	[/(\w+) woensdag/i, "woensdag", "lesson", 1]
	[/(\w+) donderdag/i, "donderdag", "lesson", 1]
	[/(\w+) vrijdag/i, "vrijdag", "lesson", 1]
	[/(\w+) zaterdag/i, "zaterdag", "lesson", 1]
	[/(\w+) zondag/i, "zondag", "lesson", 1]
	[/maandag (\w+)/i, "maandag", "lesson", 1]
	[/dinsdag (\w+)/i, "dinsdag", "lesson", 1]
	[/woensdag (\w+)/i, "woensdag", "lesson", 1]
	[/donderdag (\w+)/i, "donderdag", "lesson", 1]
	[/vrijdag (\w+)/i, "vrijdag", "lesson", 1]
	[/zaterdag (\w+)/i, "zaterdag", "lesson", 1]
	[/zondag (\w+)/i, "zondag", "lesson", 1]

	[/((volgende|aankomende) )?maandag/i, "maandag", null]
	[/((volgende|aankomende) )?dinsdag/i, "dinsdag", null]
	[/((volgende|aankomende) )?woensdag/i, "woensdag", null]
	[/((volgende|aankomende) )?donderdag/i, "donderdag", null]
	[/((volgende|aankomende) )?vrijdag/i, "vrijdag", null]
	[/((volgende|aankomende) )?zaterdag/i, "zaterdag", null]
	[/((volgende|aankomende) )?zondag/i, "zondag", null]

	[/(vorige|afgelopen) maandag/i, "-maandag", null]
	[/(vorige|afgelopen) dinsdag/i, "-dinsdag", null]
	[/(vorige|afgelopen) woensdag/i, "-woensdag", null]
	[/(vorige|afgelopen) donderdag/i, "-donderdag", null]
	[/(vorige|afgelopen) vrijdag/i, "-vrijdag", null]
	[/(vorige|afgelopen) zaterdag/i, "-zaterdag", null]
	[/(vorige|afgelopen) zondag/i, "-zondag", null]

	[/(volgende|aankomende) week/i, 1, "weeks"]
	[/(vorige|afgelopen) week/i, -1, "weeks"]
	[/(over|na) (\d+) (weken|week)/i, null, "weeks", 2]
	[/(\d+) (weken|week) geleden/i, null, "weeks", 1]

	[/(over|na) (\d+) (dagen|dag)/i, null, "days", 2]
	[/(\d+) (dagen|dag) geleden/i, null, "days", 1]
]

repeats = [
	[/\b(elke|iedere) (week|ma(aandag)?|di(nsdag)?|wo(ensdag)?|do(nderdag)?|vr(ijdag)?|za(terdag)?|zo(dag)?)\b/i, 604800]
	[/\b(elke|iedere) maand\b/i, 2629743]
	[/\b(elke|iedere) jaar\b/i, 31556916]

	[/\b(elke|iedere) (\d+) dag(en)?\b/i, "days", 2]
	[/\b(elke|iedere) (\d+) (week|weken)\b/i, "weeks", 2]
	[/\b(elke|iedere) (\d+) maand(en)?\b/i, "months", 2]
	[/\b(elke|iedere) (\d+) (jaar|jaren)\b/i, "years", 2]
]

@parseCalendarItem = (input, user = Meteor.user()) ->
	descriptionOnly = input
	date = null
	endDate = null
	appointment = null
	doBreak = no
	closestClass = null

	# Apppointment preperation.
	calcDistance = _.curry (s) -> DamerauLevenshtein(transpose: .5)(val.trim().toLowerCase(), s.trim().toLowerCase())
	z = _.filter magisterAppointment(new Date(), new Date().addDays(7)), (c) -> c.classes().length > 0
	distances = []

	for appointment in _.uniq(z, (c) -> c.classes()[0])
		name = appointment.classes()[0]
		if name.length > 4 and val.length > 4 and (( val.toLowerCase().indexOf(name.toLowerCase()) > -1 ) or ( name.toLowerCase().indexOf(val.toLowerCase()) > -1 ))
			distances.push { name, distance: 0 }
		else if (distance = calcDistance name) < 2
			distances.push { name, distance }

	closestClass = _(distances).sortBy("distance").first()

	for info, i in infos
		[reg, target, type, targetGroup] = info

		if (val = reg.exec(input)?[0])?
			targetContent = reg.exec(val)[targetGroup] if targetGroup?

			date = switch type
				when "days" then new Date().addDays (target ? +targetContent)
				when "weeks" then new Date().addDays (target ? +targetContent) * 7

				# Go to weekday.
				when null and target[0] isnt "-"
					x = moment()
					x.add 1, "days" while dutchDays[x.weekday()] isnt target
					x.toDate()
				when null and target[0] is "-"
					x = moment()
					x.add -1, "days" while dutchDays[x.weekday()] isnt target[1..]
					x.toDate()

				when "lesson" # Implicit class seaching.
					break unless closestClass?
					{ name, distance } = closestClass

					if target is 1
						appointment = _.find(z, (c) -> c.classes()[0] is name and c.begin().date() > Date.today())
						date = appointment?.begin()
						endDate = appointment?.end()
					else if target is -1
						appointment = _.find(z, (c) -> c.classes()[0] is name and c.end().date() < Date.today())
						date = appointment?.begin()
						endDate = appointment?.end()

					else if target is "yesterday--"
						appointment = _.find(z, (c) -> c.classes()[0] is name and EJSON.equals c.begin().date(), Date.today().addDays(-2))
						date = appointment?.begin()
						endDate = appointment?.end()
						doBreak = yes
					else if target is "yesterday"
						appointment = _.find(z, (c) -> c.classes()[0] is name and EJSON.equals c.begin().date(), Date.today().addDays(-1))
						date = appointment?.begin()
						endDate = appointment?.end()
						doBreak = yes
					else if target is "tomorrow"
						appointment = _.find(z, (c) -> c.classes()[0] is name and EJSON.equals c.begin().date(), Date.today().addDays(1))
						date = appointment?.begin()
						endDate = appointment?.end()
						doBreak = yes
					else if target is "tomorrow++"
						appointment = _.find(z, (c) -> c.classes()[0] is name and EJSON.equals c.begin().date(), Date.today().addDays(2))
						date = appointment?.begin()
						endDate = appointment?.end()
						doBreak = yes

					else
						appointment = _.find(z, (c) -> c.classes()[0] is name and c.begin().date() >= Date.today() and dutchDays[moment(c.begin().date()).weekday()] is target)
						date = appointment?.begin()
						endDate = appointment?.end()
						doBreak = yes

					date

			if date? then descriptionOnly = descriptionOnly.replace val, ""

		break if date? or doBreak

	unless date? # If date still isn't found, look for explicit date notations in the input.
		seperated = /\d{1,2}[-\/\\]\d{1,2}[-\/\\]\d{2,4}/.exec input
		spaces = /(\d{1,2}) (\w+|\d+) (\d{4})?/.exec input

		month = null
		year = null

		if seperated?
			seperated = seperated[0]
			descriptionOnly = descriptionOnly.replace seperated, ""

			format = if _.last(seperated.split /\D/).length is 4 then "DD-MM-YYYY" else "DD-MM-YY"
			date = moment(seperated, format).toDate()

		else if spaces?
			descriptionOnly = descriptionOnly.replace spaces, ""

			# months
			if /\D/.test spaces[2] # Month is written out.
				months = [
					/^jan(uari)?/i
					/^feb(ruari)?/i
					/^maart/i
					/^apr(il)?/i
					/^mei/i
					/^jun(i)?/i
					/^jul(i)?/i
					/^aug(ustus)?/i
					/^sep(t(ember)?)?/i
					/^okt(ober)?/i
					/^nov(ember)?/i
					/^dec(ember)?/i
				]

				month = Helpers.addZero _.indexOf(months, _.find months, (m) -> m.test spaces[2]) + 1
			else month = Helpers.addZero spaces[2] # Month is a number.

			# years
			if spaces[3]? then year = spaces[3]
			else year = new Date().getUTCFullYear()

			date = moment("#{spaces[1]}-#{month}-#{year}", "DD-MM-YYYY").toDate()

	unless date? or doBreak or not closestClass? # Implicit class seaching.
		{ name, distance } = closestClass

		appointment = _.find(z, (c) -> c.classes()[0] is name and c.begin().date() > Date.today())
		date = appointment?.begin()
		endDate = appointment?.end()

		if date?
			descriptionOnly = descriptionOnly.replace word, ""

	unless endDate? or doBreak
		if (match = /\b(ge)?hele dag\b/i.exec(input)?[0])? # Full day swag.
			descriptionOnly = descriptionOnly.replace match, ""

			date = date.date() # yup. fully readable.
			endDate = date.addDays 1, yes

		else if (match = /\S+ ?(-|tot) ?(\S+)/i.exec(input)?[2])? # Explicit end gate given.
			descriptionOnly = descriptionOnly.replace match, ""

			val = Date.parse(match)
			endDate = new Date(val) unless _.isNaN val

	# === repeats ===
	repeatInterval = null
	for repeat, i in repeats
		[reg, time, targetGroup] = info

		if (val = reg.exec(input)?[0])?
			val = +reg.exec(val)[targetGroup] if targetGroup?

			if _.isNumber(time) then repeatInterval = time
			else repeatInterval = switch time
				when "days" then 86400 * val
				when "weeks" then 86400 * 7 * val
				when "months" then 86400 * 7 * 30 * val
				when "years" then 86400 * 7 * 30 * 12 * val

	if date? and descriptionOnly? and descriptionOnly?.trim().length isnt 0
		close()

		classId = null
		if appointment? and not _.isEmpty appointment.description() # Get the classId from the appointment.
			classId = _.find(user.profile.groupInfos, (gi) -> gi.group is appointment.description())?.id

		calendarItem = new CalendarItem Meteor.userId(), descriptionOnly.trim(), date, endDate, classId
		calendarItem.repeatInterval = repeatInterval
		return calendarItem

	else return null
