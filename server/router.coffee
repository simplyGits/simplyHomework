WebApp.connectHandlers.use '/privacy', (req, res) ->
	res.writeHead 301, 'Location': 'https://www.simplyhomework.nl/privacy.html'
	res.end()

# oldbrowser
WebApp.connectHandlers.use (req, res, next) ->
	browser = WebAppInternals.identifyBrowser req.headers['user-agent']
	if browser.name isnt 'ie' or browser.major >= 9
		next()
	else
		Analytics.insert
			type: 'old-browser'
			date: new Date
			browser: browser
			userAgent: req.headers['user-agent']
			ip: req.headers['x-forwarded-for'] ? req.connection.remoteAddress

		Assets.getText 'oldBrowser.html', (e, r) ->
			res.writeHead 200
			if e?
				res.end '''
					Je browser is verouderd :(
					We raden Chrome en Firefox aan.
				'''
			else
				res.end r

	undefined

FastRender.onAllRoutes ->
	# Don't a 'basicChatInfo' subscription here, this will mess up the
	# notification handling (will sound a dong when there are unread messages
	# when the app is opened.).

	if @userId?
		@subscribe 'classes'

FastRender.route '/app', ->
	@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 4

FastRender.route '/app/calendar/:date?', (params) ->
	date = (
		time = +params.date
		if isFinite time
			new Date time
		else
			new Date
	)
	@subscribe(
		'externalCalendarItems'
		date.addDays -1, yes
		date.addDays 2, yes
	)
	@subscribe 'classes', all: yes

FastRender.route '/app/person/:id', (params) ->
	@subscribe 'status', [ params.id ]
	@subscribe 'usersData', [ params.id ]
	if params.id isnt @userId
		@subscribe 'externalCalendarItems', Date.today(), Date.today().addDays 7

FastRender.route '/app/class/:id', (params) ->
		@subscribe 'externalStudyUtils', params.id
		@subscribe 'externalGrades', classId: params.id
		@subscribe 'classInfo', params.id

FastRender.route '/app/chat/:id', (params) ->
	@subscribe 'chatMessages', params.id, 40
