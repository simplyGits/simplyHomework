Template.calendarItemDetails.helpers
	people: ->
		Meteor.users.find
			_id:
				$in: @userIds ? []
				$ne: Meteor.userId()

Template.calendarItemDetails.onCreated ->
	@subscribe 'usersData', @data?.userIds ? []

Template.calendarItemDetailsPerson.onRendered ->
	@$('[data-toggle="tooltip"]').tooltip
		container: '#calendarItemDetails'
		placement: 'bottom'
