currentPerson = -> Meteor.users.findOne FlowRouter.getParam 'id'
sameUser = -> Meteor.userId() is FlowRouter.getParam 'id'
pictures = new ReactiveVar []
personStats = new ReactiveVar

canCompare = (userId) ->
	not Session.equals('deviceType', 'phone') and
	Privacy.getOptions(userId).publishCalendarItems

compare = (userId) ->
	FlowRouter.go 'calendar', undefined, userIds: [ userId ]

Template.personView.helpers
	person: currentPerson

	backColor: ->
		p = currentPerson()

		res = (
			if not p.status? then '#000000'
			else if p.status.idle then '#FF9800'
			else if p.status.online then '#4CAF50'
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
	@autorun =>
		id = FlowRouter.getParam 'id'
		@subscribe 'status', [ id ]
		@subscribe 'usersData', [ id ]

	@autorun ->
		person = currentPerson()
		if person?
			setPageOptions
				title: "#{person.profile.firstName} #{person.profile.lastName}"

Template.personView.onRendered ->
	Mousetrap.bind 'g v', ->
		id = currentPerson()._id
		compare id if canCompare id

	@autorun ->
		FlowRouter.watchPathChange()
		slide()
		if Helpers.isDesktop()
			Meteor.defer ->
				$('[data-toggle="tooltip"]')
					.tooltip "destroy"
					.tooltip container: "body"

Template.personView.onDestroyed ->
	Mousetrap.unbind 'g v'

sharedInbetweenHours = new ReactiveVar []
Template.personSharedHours.onCreated ->
	@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 7
	@subscribe 'classes', hidden: yes

	sharedInbetweenHours.set []
	Meteor.call 'sharedInbetweenHours', @data._id, (e, r) ->
		sharedInbetweenHours.set r ? []

Template.personSharedHours.events
	'click [data-action="compare"]': (event) ->
		event.preventDefault()
		compare @_id

Template.personSharedHours.helpers
	canCompare: -> canCompare @_id
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
		).map (item) ->
			date: item.startDate
			schoolHour: item.schoolHour
			class: item.class()

		inbetweenHours = sharedInbetweenHours.get().map (obj) ->
			date: obj.start
			schoolHour: obj.schoolHour
			description: 'Tussenuur'

		_(sharedCalendarItems)
			.concat inbetweenHours
			.uniq (a) -> a.date.date().getTime()
			.sortBy (a) -> a.date.getDay() + 1
			.map (a) ->
				m = moment a.date
				name: Helpers.cap DayToDutch Helpers.weekDay a.date.date()
				hours: (
					_(sharedCalendarItems)
						.concat inbetweenHours
						.filter (x) -> m.isSame x.date, 'day'
						.sortBy 'date'
						.value()
				)
			.value()

Template.sharedChats.onCreated ->
	@subscribe 'basicChatInfo'

Template.sharedChats.helpers
	chats: ->
		ChatRooms.find({
			$and: [
				{ users: Meteor.userId() }
				{ users: Template.currentData()._id }
			]
			type: $nin: ['private', 'class']
		}, {
			sort: lastMessageTime: -1
		}).fetch()

Template['sharedChats_chatRow'].events
	'click': -> ChatManager.openChat @_id

Template.personStats.helpers
	stats: -> personStats.get()

Template.personStats.onCreated ->
	@autorun ->
		personStats.set undefined
		id = FlowRouter.getParam 'id'
		Meteor.call 'getPersonStats', (e, r) -> personStats.set r unless e?

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
