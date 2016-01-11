Template.calendarItemDetails.helpers
	people: ->
		Meteor.users.find
			_id:
				$in: @userIds ? []
				$ne: Meteor.userId()

Template.calendarItemDetails.onCreated ->
	unless @data.type is 'schoolwide'
		userIds = _.take @data?.userIds, 40
		@subscribe 'usersData', userIds

Template.calendarItemDetailsPerson.onRendered ->
	@$('[data-toggle="tooltip"]').tooltip
		container: 'body'
		placement: 'bottom'
