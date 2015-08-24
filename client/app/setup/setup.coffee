# TODO: Make some stuff configurable outside of the setup, externalServices, for
# example.

currentSetupItem = new SReactiveVar String
externalClasses  = new ReactiveVar()

currentSelectedImage      = new SReactiveVar Number, 0
currentSelectedCourseInfo = new SReactiveVar Number, 0

weekdays = new SReactiveVar [Object]

engines = []
schoolId = null
schoolEngineSub = null

# TODO: These methods are not really DRY, even overall ugly.
pictures = ->
	current = currentSelectedImage.get()

	_(externalServices.get())
		.filter (s) -> s.profileData()?.picture?
		.map (s, i) ->
			isSelected: ->
				if current is i
					'selected'
				else
					''
			value: s.profileData().picture
			index: i
			fetchedBy: s.name
		.value()

courseInfos = ->
	current = currentSelectedCourseInfo.get()

	_(externalServices.get())
		.map (s) -> s.profileData()?.courseInfo
		.reject _.isEmpty
		.map (c, i) ->
			isSelected: ->
				if current is i
					'selected'
				else
					''
			value: c
			index: i
		.value()

names = ->
	for service in externalServices.get()
		val = service.profileData()?.nameInfo
		return val if val?
	undefined

fullCount = 0
ran = no
setupItems =
	welcome:
		done: yes
		async: no

	externalServices:
		done: no
		async: no
		onDone: ->
			schoolId = _(externalServices.get())
				.map (s) -> s.profileData()?.schoolId
				.find _.negate _.isUndefined

	extractInfo:
		done: no
		async: no
		onDone: (cb) ->
			schoolQuery = $('#setup #schoolInput').val()

			$firstNameInput = $ '#setup #firstNameInput'
			$lastNameInput = $ '#setup #lastNameInput'
			any = no
			any = yes if empty($firstNameInput, '#firstNameGroup', 'Voornaam is leeg')
			any = yes if empty($lastNameInput, '#lastNameGroup', 'Achternaam is leeg')

			courseInfo = courseInfos()[currentSelectedCourseInfo.get()]?.value
			unless courseInfo?
				$courseInput = $ '#courseInput'
				value = $courseInput.val()

				courseInfo =
					year: parseInt value.replace(/\D/g, '').trim(), 10
					schoolVariant: value.replace(/\d/g, '').trim().toLowerCase()

				if _.isEmpty value.trim()
					setFieldError '#courseGroup', 'Veld is leeg'
				else unless Number.isInteger courseInfo.year
					setFieldError '#courseGroup', 'Jaartal is niet opgegeven of is niet een getal.'
					any = yes
				else if _.isEmpty courseInfo.schoolVariant
					setFieldError '#courseGroup', 'Schooltype is niet opgegeven.'
					any = yes

			return if any

			Meteor.users.update Meteor.userId(), { $set:
				'profile.schoolId': (
					schoolId ? Schools.findOne({
						name: $regex: schoolQuery, $options: 'i'
					})?._id
				)
				'profile.pictureInfo': (
					val = pictures()[currentSelectedImage.get()]
					if val?
						url: val.value
						fetchedBy: val.fetchedBy
				)
				'profile.courseInfo': courseInfo
				'profile.firstName': Helpers.nameCap $firstNameInput.val()
				'profile.lastName': Helpers.nameCap $lastNameInput.val()
				'profile.birthDate':
					# Picks the date from the first externalService that has one. Maybe we
					# should ask the user too?
					_(externalServices.get())
						.map (s) -> s.profileData()?.birthDate
						.find _.isDate

				askedExternalServices: yes
			}, ->
				cb()
				schoolEngineSub?.stop()

	plannerPrefs:
		done: no
		async: no
		onDone: ->
			Meteor.call 'storePlannerPrefs',
				weekdays:
					_(weekdays.get())
						.sortBy 'index'
						.map (d, i) ->
							weekday: i
							weight: d.selectedWeightOption
						.value()

	getExternalClasses:
		done: no
		async: yes
		func: (callback) ->
			Meteor.call 'getExternalClasses', (e, r) ->
				if e? or _.isEmpty r
					callback false
					return

				Meteor.subscribe 'scholieren.com', ->
					externalClasses.set r
					callback true

					for c in r
						Meteor.subscribe 'books', c._id
						scholierenClass = ScholierenClasses.findOne c.scholierenClassId
						books = scholierenClass?.books ? []
						books.pushMore Books.find(classId: c._id).fetch()

						bookEngine = new Bloodhound
							name: 'books'
							datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.title
							queryTokenizer: Bloodhound.tokenizers.whitespace
							local: _.uniq books, 'title'
						bookEngine.initialize()
						engines.push bookEngine

						do (c, bookEngine) ->
							Meteor.defer ->
								$("div##{c._id.toHexString()} > input")
									.typeahead null,
										source: bookEngine.ttAdapter()
										displayKey: 'title'
									.on 'typeahead:selected', (obj, datum) -> c.__method = datum

					Meteor.defer ->
						$('#getExternalClasses > #result > div')
							.colorpicker input: null
							.each ->
								$this = $ this
								$this
									.on 'changeColor', (e) -> $this.attr 'colorHex', e.color.toHex()
									.colorpicker 'setValue', "##{Random.hexString 6}"

		onDone: ->
			{ year, schoolVariant } = Meteor.user().profile.courseInfo

			unless Meteor.user().classInfos?
				Meteor.users.update Meteor.userId(), $set: classInfos: []

			for c in externalClasses.get()
				color = $("div##{c._id.toHexString()}").attr 'colorHex'

				if (method = c.__method)?
					book = Books.findOne title: val.title
					unless book?
						book = new book val.title, undefined, val.id, undefined, c._id
						Books.insert book

				Meteor.users.update Meteor.userId(), $push: classInfos:
					id: c._id
					color: color
					createdBy: c.fetchedBy
					externalInfo: c.externalInfo
					bookId: book?._id ? null

	# TODO: implement this, it should open a modal that asks
	# if the current schoolyear is over, if so we can ask the user to follow the setup
	# with stuff as `externalServices` and `externalClasses` again.
	newSchoolYear:
		done: no
		func: ->
			return undefined

			alertModal(
				"Hey!",
				Locals["nl-NL"].NewSchoolYear(),
				DialogButtons.Ok,
				{ main: "verder" },
				{ main: "btn-primary" },
				{ main: (->) },
				no
			)

	final:
		done: yes
		func: ->
			swalert
				type: "success"
				title: "Klaar!"
				text: "Wil je een complete rondleiding volgen?"
				confirmButtonText: "Rondleiding"
				cancelButtonText: "Afsluiten"
				onSuccess: -> App.runTour()

###*
# Initializes and starts the setup path.
#
# @method followSetupPath
###
@followSetupPath = ->
	return yes if ran

	setupItems.externalServices.done =
	setupItems.extractInfo.done =
	setupItems.getExternalClasses.done =
		Meteor.user().askedExternalServices
	setupItems.plannerPrefs.done = not _.isEmpty Meteor.user().plannerPrefs
	setupItems.newSchoolYear.done = yes # TODO: Dunno how're going to do this shit

	fullCount = _.filter(setupItems, (x) -> not x.done).length
	setupItems.welcome.done = setupItems.final.done = fullCount is 0

	if fullCount is 0
		no
	else
		Router.go 'setup'
		step()
		ran = yes
		yes

###*
# Moves the setup path one item further.
#
# @method step
# @return {Object} Object that gives information about the progress of the setup path.
###
step = ->
	return if fullCount is 0

	cb = ->
		pair = _(setupItems)
			.pairs()
			.find (pair) -> not pair[1].done

		unless pair?
			fullCount = 0
			# TODO: disabled because if an step failed we could get into an infinite
			# loop. Better way to handle this?
			# Also rename this var to `running`, if fixed.
			#ran = no
			Router.go 'app'
			return

		[key, item] = pair

		callback = (res = true) ->
			currentSetupItem.set key
			item.done = yes

			item.success = res

			# Continue if the current step doesn't have an UI. or if the item.func
			# encountered an error.
			step() if not Template["setup-#{key}"]? or not res

		if item.async
			item.func callback
		else
			item.func?()
			callback()

	prevItem = setupItems[currentSetupItem.get()]
	if prevItem? and prevItem.success and prevItem.onDone?
		prevItem.onDone cb

		# onDone handled at least one argument, this means that `cb` will be called,
		# no need to call it ourselves.
		return if prevItem.onDone.length > 0

	cb()
	undefined

Template.setup.helpers
	currentSetupItem: -> "setup-#{currentSetupItem.get()}"

Template.setup.onRendered ->
	$('#setup').on 'keyup', 'input:last-child', (e) -> step() if e.which is 13

Template.setupFooter.helpers
	isLast: -> _.every setupItems, 'done'

Template.setupFooter.events
	'click button': -> step()

Template['setup-extractInfo'].helpers
	pictures: pictures
	hasSchool: -> schoolId?
	courseInfos: courseInfos
	firstName: -> names()?.firstName
	lastName: -> names()?.lastName

Template['setup-extractInfo'].events
	'click #pictureSelector > img': (event) ->
		currentSelectedImage.set @index

	'click #courseInfoSelector > div': (event) ->
		currentSelectedCourseInfo.set @index

Template['setup-extractInfo'].onRendered ->
	unless schoolId?
		engine = new Bloodhound
			name: 'schools'
			datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.name
			queryTokenizer: Bloodhound.tokenizers.whitespace
			local: []

		schoolEngineSub = Meteor.subscribe 'schools', ->
			engine.add Schools.find().fetch()

		$('#setup #schoolInput')
			.typeahead {
				minLength: 2
			}, {
				source: engine.ttAdapter()
				displayKey: 'name'
			}

Template['setup-plannerPrefs'].helpers
	weekdays: -> weekdays.get()

Template.plannerPrefsDay.helpers
	weightOptions: ->
		options = [
			"Geen"
			"Weinig"
			"Gemiddeld"
			"Veel"
		]
		res = ( { name: x, selected: no, index: i } for x, i in options )
		res[@selectedWeightOption].selected = yes
		res

Template.plannerPrefsDay.events
 'change': (event) ->
	 @selected = event.target.dataset.dayIndex

Template['setup-plannerPrefs'].onRendered ->
	# TODO: When being implemented outside of the setup:
	#       Set the current data of the plannerPrefs, if available
	weekdays.set _.map Helpers.weekdays(), (name, index) ->
		name: name
		index: index
		selectedWeightOption: 2

Template['setup-getExternalClasses'].helpers
	externalClasses: -> externalClasses.get()

Template['setup-getExternalClasses'].rendered = ->
	new Spinner(
		lines: 17
		length: 7
		width: 2
		radius: 18
		corners: 0
		rotate: 0
		direction: 1
		color: '#000'
		speed: .9
		trail: 10
		shadow: no
		hwaccel: yes
		className: 'spinner'
		top: '65%'
		left: '50%'
	).spin document.getElementById 'spinner'

Template['setup-getExternalClasses'].events
	'click .fa-times': (event) -> externalClasses.set _.reject externalClasses.get(), this
	'keyup #method': (event) ->
		unless event.target.value is @__method?.title and not _.isEmpty event.target.value
			@__method =
				title: Helpers.cap event.target.value
				id: null
