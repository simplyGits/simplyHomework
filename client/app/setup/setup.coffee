# TODO: Make some stuff configurable outside of the setup, externalServices, for
# example.

currentItemIndex = new SReactiveVar Number, 0
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

ran = no
setupItems = [
	{
		name: 'welcome'
		async: no
	}

	{
		name: 'externalServices'
		async: no
		onDone: (cb) ->
			schoolId = _(externalServices.get())
				.map (s) -> s.profileData()?.schoolId
				.find _.negate _.isUndefined

			loginServices = _.filter externalServices.get(), 'loginNeeded'
			data = _.filter loginServices, (s) -> s.profileData()?
			if loginServices.length > 0 and data.length is 0
				alertModal(
					'Hé!'
					'''
						Je hebt je op geen enkele site ingelogd!
						Hierdoor zal simplyHomework niet automagisch data van sites voor je kunnen ophalen.
						Als je later toch een site wilt toevoegen kan dat altijd in je instellingen.

						Weet je zeker dat je door wilt gaan?
					'''
					DialogButtons.OkCancel
					{ main: 'doorgaan', second: 'woops' }
					{ main: 'btn-danger' }
					main: -> cb true
					second: -> cb false
				)
				return

			Meteor.users.update Meteor.userId(), $push: setupProgress: 'externalServices'
			cb yes
	}

	{
		name: 'extractInfo'
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
					schoolVariant: normalizeSchoolVariant value.replace(/\d/g, '').trim()

				if _.isEmpty value.trim()
					setFieldError '#courseGroup', 'Veld is leeg'
				else unless Number.isInteger courseInfo.year
					setFieldError '#courseGroup', 'Jaartal is niet opgegeven of is niet een getal.'
					any = yes
				else if _.isEmpty courseInfo.schoolVariant
					setFieldError '#courseGroup', 'Schooltype is niet opgegeven.'
					any = yes

			return if any

			Meteor.users.update Meteor.userId(), {
				$push: setupProgress: 'extractInfo'
				$set:
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
			}, ->
				cb()
				schoolEngineSub?.stop()
	}

	{
	name: 'plannerPrefs'
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
	}

	{
		name: 'getExternalClasses'
		async: yes
		func: (callback) ->
			colors = _.shuffle [
				'#F44336'
				'#E91E63'
				'#9C27B0'
				'#673AB7'
				'#3F51B5'
				'#03A9F4'
				'#009688'
				'#4CAF50'
				'#8BC34A'
				'#CDDC39'
				'#FFEB3B'
				'#FFC107'
				'#FF9800'
				'#FF5722'
			]

			Meteor.call 'getExternalClasses', (e, r) ->
				if e? or _.isEmpty r
					console.log 'if e? or _.isEmpty r', e
					callback false
					return

				Meteor.subscribe 'scholieren.com', ->
					externalClasses.set r.map (c, i) -> _.extend c, color: colors[ i % colors.length ]
					callback true

					for c in r
						console.log c
						Meteor.subscribe 'books', c._id
						scholierenClass = ScholierenClasses.findOne c.scholierenClassId
						books = _.union(
							scholierenClass?.books,
							Books.find(classId: c._id).fetch()
						)

						bookEngine = new Bloodhound
							name: 'books'
							datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.title
							queryTokenizer: Bloodhound.tokenizers.whitespace
							local: _.uniq books, 'title'
						bookEngine.initialize()
						engines.push bookEngine

						do (c, bookEngine) ->
							Meteor.defer ->
								$("div##{c._id} > input")
									.typeahead null,
										source: bookEngine.ttAdapter()
										displayKey: 'title'
									.on 'typeahead:selected', (obj, datum) -> c.__method = datum

		onDone: ->
			{ year, schoolVariant } = getCourseInfo()
			userId = Meteor.userId()

			for c in externalClasses.get()
				if (method = c.__method)?
					book = Books.findOne title: method.title
					unless book?
						book = new Book method.title, undefined, method.id, undefined, c._id
						Books.insert book

				Meteor.users.update userId, $push: classInfos:
					id: c._id
					color: c.color
					createdBy: c.fetchedBy
					externalInfo: c.externalInfo
					bookId: book?._id ? null
					hidden: no

			Meteor.users.update userId, $push: setupProgress: 'getExternalClasses'
	}

	{
		name: 'privacy'
		async: no
		onDone: ->
			Meteor.users.update Meteor.userId(), $push: setupProgress: 'privacy'
	}

	{
		# TODO: implement this, it should open a modal that asks
		# if the current schoolyear is over, if so we can ask the user to follow the setup
		# with stuff as `externalServices` and `externalClasses` again.
		name: 'newSchoolYear'
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
	}

	{
		name: 'final'
		func: ->
			swalert
				type: "success"
				title: "Klaar!"
				text: "Wil je een complete rondleiding volgen?"
				confirmButtonText: "Rondleiding"
				cancelButtonText: "Afsluiten"
				onSuccess: -> App.runTour()
	}
]
running = undefined

###*
# Initializes and starts the setup.
#
# @method runSetup
###
@runSetup = ->
	return undefined if ran

	setupProgress = getUserField Meteor.userId(), 'setupProgress', []
	setupProgress = setupProgress.concat [
		'welcome'
		'final'
		'plannerPrefs'
		'newSchoolYear' # TODO: Dunno how're going to do this shit
	]

	running = _.filter setupItems, (item) -> item.name not in setupProgress

	if running.length > 0
		# We need to insert the 'welcome' _before_ all the items in the `running`
		# array, and the 'final' _after_ them!
		running = _(setupItems)
			.take()
			.concat(running)
			.push _.last(setupItems)
			.value()

		Session.set 'runningSetup', yes
		ran = yes

	undefined

###*
# Moves the setup path one item further.
#
# @method step
# @return {Object} Object that gives information about the progress of the setup path.
###
step = ->
	return if running.length is 0

	cb = (success = yes) ->
		return unless success
		next = running[currentItemIndex.get() + 1]

		unless next?
			running = []
			# TODO: disabled because if an step failed we could get into an infinite
			# loop. Better way to handle this?
			# Also rename this var to `running`, if fixed.
			#ran = no
			Session.set 'runningSetup', no
			return

		callback = (res = true) ->
			currentItemIndex.set currentItemIndex.get() + 1

			next.success = res

			# Continue if the current step doesn't have an UI or if the next.func
			# encountered an error.
			step() if not Template["setup-#{next.name}"]? or not res

		if next.async
			next.func callback
		else
			next.func?()
			callback()

	current = running[currentItemIndex.get()]
	if current? and current.success and current.onDone?
		current.onDone cb

		# onDone handled at least one argument, this means that `cb` will be called,
		# no need to call it ourselves.
		return if current.onDone.length > 0

	cb()
	undefined

progressInfo = ->
	current = currentItemIndex.get()

	percentage: (current / running.length) * 100
	current: current
	amount: running.length

Template.setup.helpers
	currentSetupItem: ->
		item = running[currentItemIndex.get()]
		"setup-#{item?.name}"

	progressText: ->
		info = progressInfo()
		"#{info.current + 1}/#{info.amount}"

	progressPercentage: -> progressInfo().percentage

Template.setup.onRendered ->
	setPageOptions
		title: 'Setup'
		color: null

	@$('#setup').on 'keyup', 'input:last-child', (e) -> step() if e.which is 13

Template.setupFooter.helpers
	isLast: -> _.every running, 'done'

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

Template['setup-plannerPrefs'].onCreated ->
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
