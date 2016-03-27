# TODO: Create universal component for checkbox based settings.
# I copied this code for like 99% from the privacy package.

items = [{
	description: 'Email sturen als ik toegevoegd ben bij een project'
	short: 'email_joinedProject'
	default: yes
}, {
	description: 'Email sturen als ik een nieuw cijfer heb'
	short: 'email_newGrade'
	default: yes
}]

getUserOptions = ->
	options = getUserField Meteor.userId(), 'settings.notifications', {}

	defaults = _(items)
		.map (obj) -> [ obj.short, obj.default ]
		.object()
		.value()

	_.defaults options, defaults

Template['settings_page_notifications'].helpers
	items: ->
		options = getUserOptions()
		items.map (item) -> _.extend item, enabled: options[item.short]

Template['settings_page_notifications_item'].events
	'change': ->
			Meteor.users.update Meteor.userId(),
				$set: "settings.notifications.#{@short}": not @enabled
