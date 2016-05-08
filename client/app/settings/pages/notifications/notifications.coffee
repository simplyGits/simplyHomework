# TODO: Create universal component for checkbox based settings.
# I copied this code for like 49% from the privacy package.

# REVIEW: Do we want to have the option from the user's perspective (like it is
# now) or from our perspective?

mailItems = [{
	description: 'Email sturen als ik toegevoegd ben bij een project'
	short: 'joinedProject'
	default: yes
}, {
	description: 'Email sturen als ik een nieuw cijfer heb'
	short: 'newGrade'
	default: yes
}, {
	description: 'Email sturen als ik een nieuw bericht heb'
	short: 'newMessage'
	default: yes
}].map (item) ->
	item.dbField = "settings.notifications.email.#{item.short}"
	item

notifItems = [{
	description: 'Notificatie tonen bij nieuw chatbericht'
	short: 'chat'
	default: yes
}].map (item) ->
	item.dbField = "settings.notifications.notif.#{item.short}"
	item

getItemsArray = (items) ->
	items.map (item) ->
		item.enabled = getUserField Meteor.userId(), item.dbField, item.default
		item

Template['settings_page_notifications'].helpers
	mailItems: -> getItemsArray mailItems
	notifItems: -> getItemsArray notifItems

Template['settings_page_notifications_item'].events
	'change': ->
			Meteor.users.update Meteor.userId(),
				$set: "#{@dbField}": not @enabled
