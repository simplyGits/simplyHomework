App.info({
	name: "simplyHomework",
	description: "Een gratis, makkelijk te gebruiken, volledig automatische en awesome school hulpmiddel.",
	author: "simplyApps",
	email: "hello@simplyApps.nl",
	website: "http://simplyApps.nl",
	version: "1.0.0"
});

App.icons({
	"iphone": "resources/icons/icon-60x60.png",
	"iphone_2x": "resources/icons/icon-60x60@2x.png",
	"ipad": "resources/icons/icon-72x72.png",
	"ipad_2x": "resources/icons/icon-72x72@2x.png",

	"android_ldpi": "resources/icons/icon-36x36.png",
	"android_mdpi": "resources/icons/icon-48x48.png",
	"android_hdpi": "resources/icons/icon-72x72.png",
	"android_xhdpi": "resources/icons/icon-96x96.png"
});

App.setPreference("StatusBarOverlaysWebView", "false");
App.setPreference("StatusBarBackgroundColor", "#000000");
App.setPreference("DisallowOverscroll", "true");
App.setPreference("Orientation", "portrait");