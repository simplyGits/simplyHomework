Package.describe({
	summary: "Meteor implementation of the Mollie API.",
	version: "0.1.0",
	git: "https://github.com/simplyGits/meteor-mollie"
});

Package.onUse(function (api) {
	api.versionsFrom("METEOR@0.9.3");

	api.addFiles("./server/methods.js", "server")
	api.addFiles("./lib/mollie.js");

	api.export("Mollie");
});

Npm.depends({
	"mollie-api-node": "1.0.3"
});
