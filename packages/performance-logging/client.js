'use strict'

Meteor.startup(function () {
	if (
		performance != null &&
		PerformanceTiming && PerformanceTiming.prototype.toJSON
	) {
		Meteor.defer(function () {
			Meteor.call('performance_report', performance.timing.toJSON());
		});
	}
});
