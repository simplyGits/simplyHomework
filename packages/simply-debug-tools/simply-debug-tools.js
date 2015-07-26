const FUNC_STRINGS_KEY = "sHdebug_startFuncs";

if (Meteor.isClient) {
	Meteor.startup(function () {
		var funcStrings = localStorage[FUNC_STRINGS_KEY];

		if (funcStrings !== undefined) {
			JSON.parse(funcStrings).forEach(function (str) {
				eval("(" + str + ")()");
			});
		}
	});
}

Debug = {
	// logs all args.
	// use as cb.
	logArgs: function () {
		console.log.apply(console, arguments);
	},

	// logs all template invaldiations.
	logTemplateInvalidations: function () {
		if (!Meteor.isClient) return;

		for (key in Template) {
			var template = Template[key];
			var oldRender = template && template.rendered;

			if (typeof oldRender === "function") {
				var counter = 0;
				template.rendered = function () {
					console.log(key, 'render count: ', ++counter);
					oldRender.apply(this, arguments);
				};
			}
		}
	},

	runOnStart: function (func) {
		if (!Meteor.isClient) return;

		var items = JSON.parse(localStorage[FUNC_STRINGS_KEY] || "[]");
		localStorage[FUNC_STRINGS_KEY] = JSON.stringify(items.concat([ func.toString() ]));
	},

	logChanges: function (collection, query, options, callback) {
		collection.find(query, options).observeChanges({
			changed: function (id, fields) {
				console.log("Item with id", id, "changed, fields:", fields);
				if (callback) callback.apply(this, arguments);
			}
		});
	}
};
