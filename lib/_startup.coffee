if Meteor.isClient
	moment.locale 'nl'

	TimeSync.loggingEnabled = no

	# TODO: expand this regex or also add an matchMedia for tablets.
	tabletRegex = /ipad/i
	phoneRegex = /android|iphone|ipod|blackberry|windows phone/i
	setDeviceType = ->
		Session.set 'deviceType', (
			if tabletRegex.test(navigator.userAgent)
				'tablet'
			else if phoneRegex.test(navigator.userAgent) or
			window.matchMedia?('only screen and (max-width: 800px)')?.matches
				'phone'
			else
				'desktop'
		)

	setDeviceType()
	$(window).resize setDeviceType

Meteor.startup ->
	Accounts.config
		sendVerificationEmail: yes
