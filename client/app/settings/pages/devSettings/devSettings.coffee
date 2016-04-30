items = [{
	name: 'noChatEmojis'
	description: 'Zet smiley-naar-emoji conversie uit in chat.'
}, {
	name: 'noticeAlwaysHoverColor'
	description: 'Maak altijd het randje van een kaart op het overzicht zwart als je er met je muis over gaat.'
}, {
	name: 'newMessageNotification'
	description: 'Stuur een email als je een nieuw bericht hebt ontvangen.'
}]

Template['settings_page_devSettings'].helpers
	items: ->
		options = getUserField Meteor.userId(), 'settings.devSettings'
		items.map (item) -> _.extend item, enabled: options[item.name]

Template.devOption.helpers
	checked: -> if @enabled then 'checked' else ''

Template.devOption.events
	'change': ->
		Meteor.users.update Meteor.userId(),
			$set: "settings.devSettings.#{@name}": not @enabled
