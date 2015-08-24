var canReload = false;
var notice;

Reload._onMigrate('lazy-code-push', function (retry) {
	// Just reload if...
	if (
		// The reload is before we loaded setBigNotice, or if setBigNotice
		// isn't available for some reason.
		typeof setBigNotice !== 'function' ||

		// Or if we are on the launchPage, where setBigNotice doesn't work,
		// really, and where it doesn't really matter if the user gets
		// distracted.
		(Router && Router.current().route.getName() === 'launchPage')
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
	}
	return [canReload];
});
