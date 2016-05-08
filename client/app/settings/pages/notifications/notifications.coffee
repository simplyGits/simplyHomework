# TODO: Create universal component for checkbox based settings.
# I copied this code for like 49% from the privacy package.

# REVIEW: Do we want to have the option from the user's perspective (like it is
# now) or from our perspective?

items = [{
	description: 'Email sturen als ik toegevoegd ben bij een project'
	short: 'email_joinedProject'
	dbField: 'settings.notifications.email.joinedProject'
	default: yes
}, {
	description: 'Email sturen als ik een nieuw cijfer heb'
	short: 'email_newGrade'
	dbField: 'settings.notifications.email.newGrade'
	default: yes
}, {
	description: 'Email sturen als ik een nieuw bericht heb'
	short: 'email_newMessage'
	dbField: 'settings.notifications.email.newMessage'
	default: yes
}, {
	description: 'Notificatie tonen bij nieuw chatbericht'
	short: 'notif_chatMessage'
	dbField: 'settings.notifications.notif.chat'
	default: yes
}]

Template['settings_page_notifications'].helpers
	items: ->
		items.map (item) ->
			item.enabled = getUserField Meteor.userId(), item.dbField, item.default
			item

Template['settings_page_notifications_item'].events
	'change': ->
			Meteor.users.update Meteor.userId(),
				$set: "#{@dbField}": not @enabled
