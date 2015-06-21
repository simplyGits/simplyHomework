currentSetupItem = new ReactiveVar null

fullCount = 0
running = no
setupItems =
	welcome:
		done: yes
		async: no
	magisterInfo:
		done: no
		async: yes
		func: ->
			schoolSub = Meteor.subscribe "schools", -> $("#setMagisterInfoModal").modal backdrop: "static", keyboard: no

	plannerPrefs:
		done: no
		async: no

	getMagisterClasses:
		done: no
		func: ->
			magisterClassesComp = Tracker.autorun -> # Subscribes should be stopped when this computation is stopped later.
				Meteor.subscribe "scholieren.com"
				year = schoolVariant = null
				Tracker.nonreactive -> { year, schoolVariant } = Meteor.user().profile.courseInfo

				classes = magisterResult("classes").result ? []
				c.__scholierenClass = ScholierenClasses.findOne(-> c.description().toLowerCase().indexOf(@name.toLowerCase()) > -1) for c in classes
				magisterClasses.set classes

				for c in classes
					scholierenClass = c.__scholierenClass
					classId = Classes.findOne(name: scholierenClass?.name ? Helpers.cap(c.description()), schoolVariant: schoolVariant, year: year)?._id

					Meteor.subscribe("books", classId) if classId?

					books = scholierenClass?.books ? []
					books.pushMore Books.find({ classId }).fetch()

					engine = new Bloodhound
						name: "books"
						datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.title
						queryTokenizer: Bloodhound.tokenizers.whitespace
						local: _.uniq books, "title"

					engine.initialize()

					Meteor.defer do (engine, c) -> return ->
						$("#magisterClassesResult > div##{c.id()} > input")
							.typeahead null,
								source: engine.ttAdapter()
								displayKey: "title"
							.on "typeahead:selected", (obj, datum) -> c.__method = datum

				Meteor.defer ->
					for x in $("#magisterClassesResult > div").colorpicker(input: null)
						$(x)
							.on "changeColor", (e) -> $(@).attr "colorHex", e.color.toHex()
							.colorpicker "setValue", "##{("00000" + (Math.random() * (1 << 24) | 0).toString(16)).slice -6}"

				$("#getMagisterClassesModal").modal backdrop: "static", keyboard: no

	newSchoolYear:
		done: no
		func: ->
			alertModal "Hey!", Locals["nl-NL"].NewSchoolYear(), DialogButtons.Ok, { main: "verder" }, { main: "btn-primary" }, { main: -> return }, no
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
	return if running

	setupItems.plannerPrefs.done = setupItems.magisterInfo.done = Meteor.user().magisterCredentials?
	setupItems.getMagisterClasses.done = Meteor.user().classInfos?.length > 0
	setupItems.newSchoolYear.done = yes

	fullCount = _.filter(setupItems, (x) -> not x.done).length

	if fullCount is 0
		setupItems.welcome.done = setupItems.final.done = yes
	else
		running = yes

		document.body.innerHTML = ""
		Blaze.render Template.setup, document.body

		step()

###*
# Moves the setup path one item further.
#
# @method step
# @return {Object} Object that gives information about the progress of the setup path.
###
step = ->
	return if fullCount is 0

	item = _.find setupItems, (i) -> not i.done
	key = _(setupItems).keys().find (k) -> setupItems[k] is item
	unless item?
		fullCount = 0
		running = no
		Router.current().render(Template.app).data() # Rerender the old page.
		return

	currentSetupItem.set key
	item.func?()
	item.done = yes

Template.setup.helpers
	currentSetupItem: -> currentSetupItem.get()

Template.setup.rendered = ->
	$("div.setup").on "click", 'button[data-action="nextItem"]', step
