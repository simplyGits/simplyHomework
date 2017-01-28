{ Services } = require 'meteor/simply:external-services-connector'
{ isDesktop } = require 'meteor/device-type'

Template.calendarItemDetails.helpers
	people: ->
		# TODO: when viewing the schedule of someone else it would be nice to show
		# the currentUser too.
		if @type is 'schoolwide'
			[]
		else
			Meteor.users.find
				_id:
					$in: @userIds ? []
					$ne: Meteor.userId()
	relativeTime: -> @relativeTime? yes
	contentDescription: ->
		description = @content?.description
		if description?
			Helpers.convertLinksToAnchor _.escape description

	fileCount: -> @files.length
	files: ->
		@files()
			.map (file) -> file.buildAnchorTag().outerHTML
			.join ', '

	hasChat: ->
		ChatRooms.find(
			type: 'class'
			'classInfo.ids': @classId
			'classInfo.group': @group()
		).count() > 0

	services: ->
		_(@externalInfos)
			.keys()
			.map (k) -> _.find Services, name: k
			.pluck 'friendlyName'
			.sortBy()
			.join ', '

Template.calendarItemDetails.events
	'click [data-action="chat"]': (event) ->
		event.preventDefault()
		ChatManager.openClassChat @classId if @classId?

Template.calendarItemDetails.onCreated ->
	@subscribe 'files', @data?.fileIds ? []

	unless @data.type is 'schoolwide'
		userIds = _.take @data?.userIds, 40
		@subscribe 'usersData', userIds

Template.calendarItemDetailsPerson.onRendered ->
	if isDesktop()
		@$('[data-toggle="tooltip"]').tooltip
			container: 'body'
			placement: 'bottom'
