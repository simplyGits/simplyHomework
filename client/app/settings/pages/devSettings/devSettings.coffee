items = [{
	name: 'noChatEmojis'
	description: 'Zet smiley-naar-emoji conversie uit in chat.'
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