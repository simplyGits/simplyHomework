currentPerson = -> Meteor.users.findOne FlowRouter.getParam 'id'
sameUser = -> Meteor.userId() is FlowRouter.getParam 'id'
pictures = new ReactiveVar []

Template.personView.helpers
	person: currentPerson

	backColor: ->
		res = (
			if not @status? then '#000000'
			else if @status.idle then '#FF9800'
			else if @status.online then '#4CAF50'
			else '#EF5350'
		)

		setPageOptions color: res
		res
	sameUser: sameUser

Template.personView.events
	'click .personPicture, click #changePictureButton': ->
		return unless sameUser()
		analytics?.track 'Open ChangePictureModal'
		showModal 'changePictureModal'

	'click i#reportButton': ->
		analytics?.track 'Open ReportUserModal'
		showModal 'reportUserModal', undefined, currentPerson
	"click button#chatButton": -> ChatManager.openPrivateChat @_id

Template.personView.onCreated ->
	@subscribe 'classes', hidden: yes

	@autorun =>
		unless sameUser()
			@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 7

		id = FlowRouter.getParam 'id'
		@subscribe 'status', [ id ]
		@subscribe 'usersData', [ id ], onReady: ->
			person = Meteor.users.findOne id
			if person?
				setPageOptions
					title: "#{person.profile.firstName} #{person.profile.lastName}"

			else
				notFound()

Template.personView.onRendered ->
	slide()

	@autorun ->
		FlowRouter.watchPathChange()
		Meteor.defer ->
			$('[data-toggle="tooltip"]')
				.tooltip "destroy"
				.tooltip container: "body"

# TODO: take a look if this can be thrown away.
###
Template.personsInClasses.helpers
	people: ->
		return []
		calendarItems = CalendarItems.find(
			userIds: Meteor.userId()
			startDate: $gte: Date.today()
			endDate: $lte: Date.today().addDays 7
		).fetch()

		userIds = _(calendarItems)
			.filter (item) -> item.length > 1
			.pluck 'userIds'
			.flatten()
			.uniq()
			.reject (id) -> id is Meteor.userId()
			.value()

		Meteor.users.find {
			_id: Meteor.userId()
			#_id: $in: userIds
		}, {
			limit: if Session.get('isPhone') then 5 else 30
		}
###

Template.personSharedHours.helpers
	days: ->
		sharedCalendarItems = CalendarItems.find(
			$and: [
				{ userIds: Meteor.userId() }
				{ userIds: Template.currentData()._id }
			]
			startDate: $gte: Date.today()
			endDate: $lte: Date.today().addDays 7
			schoolHour:
				$exists: yes
				$ne: null
		).fetch()

		_(sharedCalendarItems)
			.uniq (a) -> a.startDate.date().getTime()
			.sortBy (a) -> a.startDate.getDay() + 1
			.map (a) ->
				name: Helpers.cap DayToDutch Helpers.weekDay a.startDate.date()
				hours: (
					_(sharedCalendarItems)
						.filter (x) -> EJSON.equals x.startDate.date(), a.startDate.date()
						.sortBy 'startDate'
						.value()
				)
			.value()

Template.reportUserModal.events
	'click button#goButton': ->
		analytics?.track 'User Reported'

		checked = $ 'div#checkboxes input:checked'
		reportGrounds = new Array checked.length
		for checkbox, i in checked
			reportGrounds[i] = $(checkbox).closest('div').attr 'id'

		if reportGrounds.length is 0
			shake '#reportUserModal'
			return

		name = @profile.firstName
		$('#reportUserModal').modal 'hide'
		Meteor.call 'reportUser', @_id, reportGrounds, (e, r) ->
			if e?
				message = switch e.error
					when 'rate-limit' then 'Je hebt de afgelopen tijd téveel mensen gerapporteerd, probeer het later opnieuw.'
					when 'already-reported' then "Je hebt #{name} al gerapporteerd om dezelfde reden(en)."
					else 'Onbekende fout tijdens het rapporteren'

				notify message, 'error'

			else
				notify "#{name} gerapporteerd.", 'notice'

Template.changePictureModal.onCreated ->
	getProfileDataPerService (e, r) ->
		if e?
			notify "Fout tijdens het ophalen van de foto's", 'error'
			Kadira.trackError 'ChangePictureModal', e.toString(), stacks: EJSON.stringify e
			$('#changePictureModal').modal 'hide'
		else
			pictures.set(
				_(r)
					.pairs()
					.filter ([key, val]) -> val.picture?
					.map ([ key, val ]) ->
						fetchedBy: key
						value: val.picture
						selected: ->
							if key is getUserField(Meteor.userId(), 'profile.pictureInfo.fetchedBy')
								'selected'
							else
								''
					.value()
			)

Template.changePictureModal.helpers
	pictures: -> pictures.get()
	loadingPictures: -> _.isEmpty pictures.get()

Template.pictureSelectorItem.events
	'click': (event) ->
		Meteor.users.update Meteor.userId(), $set:
			'profile.pictureInfo':
				url: @value
				fetchedBy: @fetchedBy

		analytics?.track 'Profile Picture Changed'
		$('#changePictureModal').modal 'hide'
