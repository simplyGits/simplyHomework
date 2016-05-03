items = [{
	name: 'noChatEmojis'
	description: 'Zet smiley-naar-emoji conversie uit in chat.'
}, {
	name: 'noticeAlwaysHoverColor'
	description: 'Maak altijd het randje van een kaart op het overzicht zwart als je er met je muis over gaat.'
}, {
	name: 'newMessageNotification'
	description: 'Stuur een email als je een nieuw bericht hebt ontvangen.'
}, {
	name: 'tfaEnabled'
	description: '2-staps authenticatie aanzetten.'
	afterChange: (val) ->
		return unless val
		showModal '2fa_key_modal'
}]

Template['settings_page_devSettings'].onRendered ->
	unless Helpers.isDesktop()
		_.remove items, name: 'tfaEnabled'

Template['settings_page_devSettings'].helpers
	items: ->
		options = getUserField Meteor.userId(), 'settings.devSettings'
		items.map (item) -> _.extend item, enabled: options[item.name]

Template.devOption.helpers
	checked: -> if @enabled then 'checked' else ''

Template.devOption.events
	'change': ->
		newState = not @enabled
		@beforeChange? newState
		Meteor.users.update Meteor.userId(), {
			$set: "settings.devSettings.#{@name}": newState
		}, (e) => @afterChange? newState unless e?
