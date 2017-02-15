# TODO: clean all of this shit up.

# TODO: a real selector component

SReactiveVar = require('meteor/simply:strict-reactive-var').default
{ Services } = require 'meteor/simply:external-services-connector'

currentSelectedImage      = new SReactiveVar Number, 0
currentSelectedCourseInfo = new SReactiveVar Number, 0

weekdays = new SReactiveVar [Object]

schoolId = null
schoolEngineSub = null

setup = undefined

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
			service: _.find Services, name: s.name
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

addProgress = (item, cb) ->
	ga 'send', 'event', 'setup', 'progress', item
	Meteor.users.update Meteor.userId(), {
		$addToSet: setupProgress: item
	}, cb

# TODO: automatically track progress
class @Setup
	@setupItems: [
		{
			name: 'intro'
			async: no
			onDone: (cb) -> addProgress 'intro', -> cb yes
		}

		{
			name: 'cookies'
			async: no
			onDone: (cb) -> addProgress 'cookies', -> cb yes
		}

		{
			name: 'externalServices'
			async: no
			onDone: (cb) ->
				schoolId = _(externalServices.get())
					.map (s) -> s.profileData()?.schoolId
					.find _.negate _.isUndefined

				done = (success) ->
					if success?
						addProgress 'externalServices', -> cb yes
					else
						cb no

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
						main: -> done yes
						second: -> done no
					)
				else
					done yes
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
					$addToSet: setupProgress: 'extractInfo'
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
							# Picks the date from the first externalService that has one.
							# REVIEW: Maybe we should ask the user too?
							_(externalServices.get())
								.map (s) -> s.profileData()?.birthDate
								.find _.isDate
				}, ->
					cb yes
					schoolEngineSub?.stop()
		}

		{
			name: 'getExternalClasses'
			async: yes
			visible: no
			func: (callback) ->
				Meteor.call 'fetchExternalPersonClasses', (e, r) ->
					addProgress 'getExternalClasses', ->
						if e?
							callback false
						else
							Meteor.call 'bootstrapUser'
							callback true
		}

		{
			name: 'privacy'
			async: no
			onDone: (cb) -> addProgress 'privacy', -> cb yes
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
			name: 'first-use'
			func: ->
				addProgress 'first-use', ->
					name = getUserField Meteor.userId(), 'profile.firstName'
					document.location.href = "https://www.simplyhomework.nl/first-use##{name}"
		}
	]

	constructor: (setupProgress) ->
		@currentIndex = new SReactiveVar Number, -1
		@running = _.filter Setup.setupItems, (item) ->
			item.name not in setupProgress

	###*
	# Finish the current setup step and step one item futher in the setup path.
	#
	# @method finishStep
	# @return {Object} Object that gives information about the progress of the setup path.
	###
	finishStep: ->
		step = (success) =>
			# REVIEW: What to do here?
			return unless success

			callback = (success) =>
				@currentIndex.set @currentIndex.get() + 1
				@current().success = success

				# Continue if the current step doesn't have an UI or if the next.func
				# encountered an error.
				if not Template["setup-#{next.name}"]? or not success
					@finishStep()

			next = @next()

			if next?
				# Goto the next item.
				if next.async
					next.func callback
				else
					try
						next.func?()
						callback yes
					catch
						callback no
			else
				# We're done with the setup, close it.
				@_stop()
				return

		current = @current()
		if current? and current.success and current.onDone?
			current.onDone? step
		else
			step yes

		undefined

	current: -> @running[@currentIndex.get()]
	next: -> @running[@currentIndex.get() + 1]

	###*
	# @method progressInfo
	# @return Object
	###
	progressInfo: ->
		current = @currentIndex.get()
		length = _(@running)
			.reject visible: no
			.value()
			.length

		percentage: (current / length) * 100
		current: current
		amount: length

	_stop: ->
		@running = []
		Session.set 'runningSetup', no

	_start: ->
		if @running.length > 0
			Session.set 'runningSetup', yes
			Meteor.defer =>
				@finishStep()

	###*
	# Initializes and starts the setup.
	#
	# @method run
	###
	@run: ->
		return if setup?
		Session.set 'runningSetup', no # HACK: this hacks around the auto migration starting the setup when it shouldn't.
		setupProgress = getUserField Meteor.userId(), 'setupProgress'
		return unless setupProgress?

		setupProgress = setupProgress.concat [
			'newSchoolYear' # TODO: Dunno how're going to do this shit
		]

		setup = new Setup setupProgress
		setup._start()
		undefined

Template.setup.helpers
	currentSetupItem: ->
		item = setup?.current()
		if item?
			"setup-#{item.name}"

	progressText: ->
		info = setup?.progressInfo()
		if info?
			"#{info.current + 1}/#{info.amount}"

	progressPercentage: ->
		info = setup?.progressInfo()
		if info?
			info.percentage

Template.setup.onRendered ->
	@$('#setup').on 'keyup', 'input:last-child', (e) ->
		if e.which is 13
			setup.finishStep()

Template.setupFooter.helpers
	isLast: -> _.every setup?.running, 'done'

Template.setupFooter.events
	'click button': -> setup.finishStep()

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
