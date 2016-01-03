Template.privacyOption.events
	'change': ->
		Meteor.users.update Meteor.userId(),
			$set: "settings.privacy.#{@short}": not @enabled

Template.privacySettings.helpers
	privacyOptions: ->
		options = Privacy.getOptions Meteor.userId()
		Privacy.options.map (item) -> _.extend item, enabled: options[item.short]
