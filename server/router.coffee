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
