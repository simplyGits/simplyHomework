# oldbrowser warning.
WebApp.connectHandlers.use (req, res, next) ->
	version = /\bMSIE ([\d.]+)\b/i.exec(req.headers['user-agent'])?[1]
	if not version? or parseFloat(version) >= 9
		next()
	else
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
