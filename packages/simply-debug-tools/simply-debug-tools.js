const FUNC_STRINGS_KEY = 'sHdebug_startFuncs';

if (Meteor.isClient) {
	Meteor.startup(function () {
		var funcStrings = localStorage[FUNC_STRINGS_KEY];

		if (funcStrings !== undefined) {
			JSON.parse(funcStrings).forEach(function (str) {
				eval('(' + str + ')()');
			});
		}
	});
}

Debug = {
	/**
	 * Logs all args, use as callback on an async function.
	 * @property logArgs
	 * @type Function
	 * @final
	 */
	logArgs: function () {
		console.log.apply(console, arguments);
	},

	/**
	 * Logs all template invalidations.
	 * @method logTemplateInvalidations
	 */
	logTemplateInvalidations: function () {
		if (!Meteor.isClient) return;

		for (var key in Template) {
			var template = Template[key];
			var oldRender = template && template.rendered;

			if (typeof oldRender === 'function') {
				var counter = 0;
				template.rendered = function () {
					console.log(key, 'render count: ', ++counter);
					oldRender.apply(this, arguments);
				};
			}
		}
	},

	/**
	 * Runs the given `func` on client startup (Meteor.startup()) every time
	 * the site/app is loaded.
	 *
	 * @method runOnStart
	 * @param {Function} func The function to load.
	 */
	runOnStart: function (func) {
		if (!Meteor.isClient) return;

		var items = JSON.parse(localStorage[FUNC_STRINGS_KEY] || '[]');
		localStorage[FUNC_STRINGS_KEY] = JSON.stringify(items.concat([ func.toString() ]));
	},

	/**
	 * Logs the changes on the given `collection` on items matching the given
	 * `query`.
	 *
	 * @method logChanges
	 * @param {Mongo.Collection} collection The collection to observe.
	 * @param {Object} [query]
	 * @param {Object} [options] Optional object of options passed onto `collection.find`.
	 * @param {Function} [callback] Optional callback to call everytime `collection` is changed. Gets called with { 0: id, 1: fields }.
	 */
	logChanges: function (collection, query, options, callback) {
		collection.find(query, options).observeChanges({
			changed: function (id, fields) {
				console.log('Item with id', id, 'changed, fields:', fields);
				callback && callback.apply(this, arguments);
			},
		});
	}
};
