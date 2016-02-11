Template['settings_page_logins'].helpers
	current: -> Logins.current()
	logins: -> Logins.others()

Template['settings_page_logins_login'].events
	'click [data-action="kill"]': -> Logins.kill @_id
