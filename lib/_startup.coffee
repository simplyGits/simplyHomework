Meteor.startup ->
	Accounts.config
		sendVerificationEmail: yes

	blocked = [
		'heading'
		'hr'
		'del'
	]

	renderer = new marked.Renderer()
	renderer.html = (str) -> str.replace /<[^>]*>/, ''
	passthrough = (str) -> str
	for item in blocked
		renderer[item] = passthrough

	marked.setOptions
		renderer: renderer
		smartypants: yes
