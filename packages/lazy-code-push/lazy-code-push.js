var canReload = false;
var notice;
var onReconnected;

Tracker.autorun(function () {
	var connected = Meteor.status().connected;
	if (connected) {
		onReconnected && onReconnected();
	} else if (notice !== undefined) {
		notice.hide();
		notice = undefined;
	}
});

Reload._onMigrate('lazy-code-push', function (retry) {
	var onIgnoredRoute = false;
	if (Package['kadira:flow-router']) {
		var FlowRouter = Package['kadira:flow-router'].FlowRouter;
		onIgnoredRoute = [
			'launchPage',
			undefined, // 404 route
		].indexOf(FlowRouter.getRouteName()) > -1;
	}

	// Just reload if...
	if (
		// The reload is before we loaded setBigNotice, or if setBigNotice
		// isn't available for some reason.
		typeof setBigNotice !== 'function' ||

		// Or if we are on a route where setBigNotice doesn't work,
		// really, and where it doesn't really matter if the user gets
		// distracted.
		onIgnoredRoute ||

		// Or in setup, where setBigNotice also doesn't work.
		Session.get('runningSetup') ||

		// Or the `justfuckingreload` option is `'true'`.
		localStorage['justfuckingreload'] === 'true'
	) {
		return [true];
	}

	// If we didn't ask the user yet if they want to reload, ask.
	// We only want to ask once, even if the user answered no.
	if (notice === undefined) {
		notice = setBigNotice({
			content: 'simplyHomework is geüpdatet! Klik hier om de pagina te herladen.',
			onClick: function () {
				notice.hide();
				canReload = true;
				retry();
			},
		});

		onReconnected = retry;
	}
	return [canReload];
});
