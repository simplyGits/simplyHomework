'use strict'

Meteor.startup(function () {
	if (
		performance != null &&
		PerformanceTiming && PerformanceTiming.prototype.toJSON
	) {
		const res = performance.timing.toJSON();

		const connection = navigator.connection ||
			navigator.mozConnection ||
			navigator.webkitConnection;
		if (connection != null) {
			res.connectionType = connection.type;
		}

		Meteor.defer(function () {
			Meteor.call('performance_report', res);
		});
	}
});
