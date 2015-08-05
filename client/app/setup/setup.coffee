# TODO: Make some stuff configurable outside of the setup, externalServices, for
# example.

currentSetupItem = new SReactiveVar String
externalClasses  = new ReactiveVar()
externalServices = new SReactiveVar [Object]

currentSelectedImage      = new SReactiveVar Number, 0
currentSelectedCourseInfo = new SReactiveVar Number, 0

weekdays = new SReactiveVar [Object]

engines = []

# TODO: These methods are not really DRY, even overall ugly.
pictures = ->
	current = currentSelectedImage.get()

	_(externalServices.get())
		.filter (s) -> s.profileData()?.picture?
		.map (s, i) ->
			isSelected: ->
				if current is i
					any = yes
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
		.reject _.isUndefined
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
		done: no
		async: no

	externalServices:
		done: no
		async: no

	extractInfo:
		done: no
		async: no
		onDone: (cb) ->
			firstName = $('.setup #firstNameInput').val()
			lastName = $('.setup #lastNameInput').val()

			sub = Meteor.subscribe 'schools', ->
				Meteor.users.update Meteor.userId(), { $set:
					'profile.schoolId': (
						externalId = _(externalServices.get())
							.map (s) -> s.profileData()?.externalSchoolId
							.find _.negate _.isUndefined

						Schools.findOne({ externalId })._id
					)
					'profile.pictureInfo': (
						val = pictures()[currentSelectedImage.get()]
						if val?
							url: val.value
							fetchedBy: val.fetchedBy
					)
					'profile.courseInfo': courseInfos()[currentSelectedCourseInfo.get()]?.value
					'profile.firstName': Helpers.nameCap (names()?.firstName ? firstName)
					'profile.lastName': Helpers.nameCap (names()?.lastName ? lastName)
					'profile.birthDate':
						_(externalServices.get())
							.map (s) -> s.profileData()?.birthDate
							.find _.isDate
				}, ->
					cb()
					sub.stop()

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
		done: no
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
	return if ran

	setupItems.externalServices.done =
	setupItems.extractInfo.done =
		not _.isEmpty Meteor.user().externalServices
	setupItems.plannerPrefs.done = not _.isEmpty Meteor.user().plannerPrefs
	setupItems.getExternalClasses.done = Meteor.user().classInfos?.length > 0
	setupItems.newSchoolYear.done = yes # TODO: Dunno how're going to do this shit

	fullCount = _.filter(setupItems, (x) -> not x.done).length

	if fullCount is 0
		setupItems.welcome.done = setupItems.final.done = yes
	else
		ran = yes
		Router.go 'setup'
		step()

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
			step() if not Template[key]? or not res

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
	currentSetupItem: -> currentSetupItem.get()

Template.setup.onRendered ->
	$('div.setup').on 'click', 'button[data-action="nextItem"]', step

Template.setupFooter.helpers
	isLast: -> _.every setupItems, 'done'

Template.externalServices.helpers
	externalServices: -> _.filter externalServices.get(), 'loginNeeded'

Template.externalServices.events
	'click .externalServiceButton': (event) ->
		if @template?
			view = Blaze.renderWithData @template, this, document.body
			$("##{@templateName}")
				.modal()
				.on 'hidden.bs.modal', -> Blaze.remove view

Template.externalServices.onRendered ->
	Meteor.call 'getModuleInfo', (e, r) ->
		services = _(r)
			.map (service) ->
				profileData = new SReactiveVar Object
				_.extend service,
					templateName: "#{service.name}InfoModal"
					template: Template["#{service.name}InfoModal"]

					setProfileData: (o) -> profileData.set o
					profileData: -> profileData.get()
			.each (service) ->
				unless service.loginNeeded
					# Create data for services that don't need to be logged into
					# (eg. Gravatar)
					Meteor.call 'createServiceData', service.name, (e, r) ->
						if e? then console.error e
						else service.setProfileData r
			.value()

		externalServices.set services

Template.extractInfo.helpers
	pictures: pictures
	courseInfos: courseInfos
	firstName: -> names()?.firstName
	lastName: -> names()?.lastName

Template.extractInfo.events
	'click #pictureSelector > img': (event) ->
		currentSelectedImage.set @index

	'click #courseInfoSelector > div': (event) ->
		currentSelectedCourseInfo.set @index

Template.plannerPrefs.helpers
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

Template.plannerPrefs.rendered = ->
	# TODO: When being implemented outside of the setup:
	#       Set the current data of the plannerPrefs, if available
	weekdays.set _.map Helpers.weekdays(), (name, index) ->
		name: name
		index: index
		selectedWeightOption: 2

Template.getExternalClasses.helpers
	externalClasses: -> externalClasses.get()

Template.getExternalClasses.rendered = ->
	opts =
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

	spinner = new Spinner(opts).spin document.getElementById 'spinner'

Template.getExternalClasses.events
	'click .fa-times': (event) -> externalClasses.set _.reject externalClasses.get(), this
	'keyup #method': (event) ->
		unless event.target.value is @__method?.title and not _.isEmpty event.target.value
			@__method =
				title: Helpers.cap event.target.value
				id: null
