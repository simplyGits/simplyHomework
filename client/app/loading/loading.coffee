Spinner = require 'spin.js'

Template.loading.onRendered ->
	@spinner = new Spinner(
		lines: 17
		length: 7
		width: 2
		radius: 18
		corners: 0
		rotate: 0
		direction: 1
		color: '#000'
		speed: .9
		trail: 10
		shadow: no
		hwaccel: yes
		className: 'spinner'
		top: '50%'
		left: '50%'
	).spin @$('#spinner')[0]

Template.loading.onDestroyed ->
	@spinner?.stop()
