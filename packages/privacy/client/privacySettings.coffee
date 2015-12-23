Template.privacyOption.events
	'change': ->
		Meteor.users.update Meteor.userId(),
			$set: "privacyOptions.#{@short}": not @enabled

Template.privacySettings.helpers
	privacyOptions: ->
		options = Privacy.getOptions Meteor.userId()

		Debug.logThrough Privacy.options.map (item) -> _.extend item,
			enabled: options[item.short]
