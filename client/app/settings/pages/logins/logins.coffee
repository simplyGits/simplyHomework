Logins = require 'meteor/simply:logins'

Template['settings_page_logins'].helpers
	current: -> Logins.current()
	logins: ->
		_.sortByOrder(
			Logins.others()
			[ (l) -> l.lastLogin?.date.getTime() ]
			[ 'desc' ]
		)

Template['settings_page_logins'].onCreated ->
	@subscribe 'logins'

Template['settings_page_logins_login'].events
	'click [data-action="kill"]': -> Logins.kill @_id
