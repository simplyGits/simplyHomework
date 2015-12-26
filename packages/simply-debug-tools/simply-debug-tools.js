if (Meteor.isServer) {
	Meteor.methods({
		log: function (message) {
			check(message, String);
			console.log(message);
		},
	});
}

/**
 * @class Debug
 * @static
 */
Debug = {
	/**
	 * Logs the given message on the server with the given type, regardless of
	 * the platform this function is called on.
	 * @method serverLog
	 * @param {String} message
	 */
	serverLog: function (message) {
		return Meteor.call('log', message);
	},

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
	},

	/**
	 * Reloads the page the way Meteor does with a hot code push, thus saving
	 * the state of packages, that use `Reload._onMigrate`.
	 *
	 * @method reload
	 */
	reload: function () {
		Reload._reload();
	},

	/**
	 * Disables lazy hot code push.
	 * @method justfuckingreload
	 * @param {Boolean} val Whether or not to just fucking reload.
	 */
	justfuckingreload: function (val) {
		if (!Meteor.isClient) return;

		localStorage['justfuckingreload'] = val;
		return localStorage['justfuckingreload'];
	},

	/**
	 * `console.trace`s `val` and returns it.
	 * @method logThrough
	 * @param {any} val
	 * @return {any}
	 */
	logThrough: function (val) {
		console.log(val);
		return val;
	},
};
