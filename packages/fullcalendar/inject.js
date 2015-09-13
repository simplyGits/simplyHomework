if (!Package.appcache) {
	var jstag = '<script src="/packages/simply_fullcalendar/fullcalendar/dist/fullcalendar.js"></script>'
	var langtag = '<script src="/packages/simply_fullcalendar/fullcalendar/dist/lang/nl.js"></script>'
	var csstag = '<link href="/packages/simply_fullcalendar/fullcalendar/dist/fullcalendar.css" rel="stylesheet">'
	var str = [
		jstag,
		langtag,
	].join('\n');

	function testUserAgent (ua) {
		return !/android|iphone|ipod|blackberry|windows phone/i.test(ua);
	}

	WebApp.connectHandlers.use(function (req, res, next) {
		if (Inject.appUrl(req.url)) {
			Inject.rawModHtml('fullcalendar', function (html, _res) {
				if (_res === res && testUserAgent(req.headers['user-agent'])) {
					return html
						.replace('<head>', '<head>\n' + csstag)
						.replace('</head>', str + '\n</head>');
				} else {
					return html;
				}
			});
		}
		next();
	});
}
