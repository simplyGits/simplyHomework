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
	}
};
