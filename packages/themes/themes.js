/* global Inject */
'use strict';

if (!Package.appcache) {
	// TODO: Optimize this function.
	const getNthDayTimeOfThisMonth = function (day, nth) {
		const now = new Date();
		let first = new Date(now.getFullYear(), now.getMonth());
		let delta = day - first.getDay() + (7 * ( nth - 1 ));
		if (delta < 0) {
			delta += 6 - delta;
		}
		first.setDate(first.getDate() + delta);
		return first.getTime();
	};

	const themes = [
		{
			name: 'paarse-vrijdag',
			func: function () {
				const today = Date.today();
				return (
					today.getMonth() === 11 &&
					today.getTime() === getNthDayTimeOfThisMonth(5, 2)
				);
			},
		},
		{
			name: 'christmas',
			func: function () {
				const today = Date.today();
				return (
					today.getMonth() === 11 &&
					today.getDate() === 25
				);
			},
		},
		{
			name: 'aprilfools2016',
			func: function () {
				return Date.today().getTime() === 1459461600000;
			},
		},
	];

	WebApp.connectHandlers.use(function (req, res, next) {
		const item = _.find(themes, (theme) => theme.func());

		if (item === undefined) {
			next();
			return;
		}

		Inject.rawModHtml('themes', function (html, _res) {
			if (_res === res && Inject.appUrl(req.url)) {
				return html.replace('<body>', `<body class="${item.name}">`);
			} else {
				return html;
			}
		});

		next();
	});
}
