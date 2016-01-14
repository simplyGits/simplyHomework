Template.calendarItemDetails.helpers
	people: ->
		if @type is 'schoolwide'
			[]
		else
			Meteor.users.find
				_id:
					$in: @userIds ? []
					$ne: Meteor.userId()
	relativeTime: -> @relativeTime yes

Template.calendarItemDetails.onCreated ->
	unless @data.type is 'schoolwide'
		userIds = _.take @data?.userIds, 40
		@subscribe 'usersData', userIds

Template.calendarItemDetailsPerson.onRendered ->
	if Helpers.isDesktop()
		@$('[data-toggle="tooltip"]').tooltip
			container: 'body'
			placement: 'bottom'
