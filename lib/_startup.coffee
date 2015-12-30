if Meteor.isClient
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

	blocked = [
		'heading'
		'hr'
		'del'
		'list'
	]

	renderer = new marked.Renderer()
	renderer.html = (str) -> str.replace /<[^>]*>/, ''
	renderer.link = (href, title, text) ->
		if /^javascript:/.test href
			text
		else
			a = document.createElement 'a'
			a.href = href
			a.title = title
			a.innerText = text
			a.target = '_blank'
			a.outerHTML
	# People use '* <text>' to give an correction, on a previous text message.
	# But markdown interperts that as an bulleted list.
	renderer.listitem = (str) -> "* #{str}"

	passthrough = (str) -> str
	for item in blocked
		renderer[item] = passthrough

	marked.setOptions
		renderer: renderer
		smartypants: yes
