Template.calendarItemDetails.helpers
	people: ->
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
		@files
			.map (file) =>
				a = document.createElement 'a'
				a.href = "/ci/#{@_id}/f/#{file._id}"
				a.target = '_blank'
				a.download = file.name
				a.textContent = file.name
				a.outerHTML
			.join ', '

Template.calendarItemDetails.events
	'click [data-action="chat"]': (event) ->
		event.preventDefault()
		classId = @class()?._id
		ChatManager.openClassChat classId if classId?

Template.calendarItemDetails.onCreated ->
	unless @data.type is 'schoolwide'
		userIds = _.take @data?.userIds, 40
		@subscribe 'usersData', userIds

Template.calendarItemDetailsPerson.onRendered ->
	if Helpers.isDesktop()
		@$('[data-toggle="tooltip"]').tooltip
			container: 'body'
			placement: 'bottom'
