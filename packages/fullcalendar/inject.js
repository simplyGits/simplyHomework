/* global Inject */
if (!Package.appcache) {
	const csstag = '<link href="/packages/simply_fullcalendar/dist/fullcalendar.css" rel="stylesheet">';
	const jstag = '<script src="/packages/simply_fullcalendar/dist/fullcalendar.js"></script>';
	const langtag = '<script src="/packages/simply_fullcalendar/dist/lang/nl.js"></script>';

	const head = [
		csstag,
	].join('\n');
	const body = [
		jstag,
		langtag,
	].join('\n');

	const testUserAgent = function (ua) {
		return !/android|iphone|ipod|blackberry|windows phone/i.test(ua);
	}

	WebApp.connectHandlers.use(function (req, res, next) {
		if (Inject.appUrl(req.url) && testUserAgent(req.headers['user-agent'])) {
			Inject.rawHead('fullcalendar', head);
			Inject.rawModHtml('fullcalendar', function (html) {
				return html.replace('</body>', `${body}</body>`);
			});
		}
		next();
	});
}
