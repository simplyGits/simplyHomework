if (!Package.appcache) {
	// TODO: Optimize this function.
	var getNthDayTimeOfThisMonth = function (day, nth) {
		var now = new Date();
		var first = new Date(now.getFullYear(), now.getMonth());
		var delta = day - first.getDay() + (7 * ( nth - 1 ));
		if (delta < 0) {
			delta += 6 - delta;
		}
		first.setDate(first.getDate() + delta);
		return first.getTime();
	};

	var themes = [
		{
			name: 'paarse-vrijdag',
			func: function () {
				var today = Date.today();
				return (
					today.getMonth() === 11 &&
					today.getTime() === getNthDayTimeOfThisMonth(5, 2)
				);
			},
		},
	];

	WebApp.connectHandlers.use(function (req, res, next) {
		var item = _.find(themes, function (theme) {
			return theme.func();
		});

		if (item === undefined) {
			next();
			return;
		}

		Inject.rawModHtml('themes', function (html, _res) {
			if (_res === res && Inject.appUrl(req.url)) {
				return html.replace('<body>', '<body class="' + item.name + '">');
			} else {
				return html;
			}
		});

		next();
	});
}
