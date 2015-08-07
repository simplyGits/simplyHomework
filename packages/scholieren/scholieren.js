'use strict';

var settings = Meteor.settings && Meteor.settings.scholieren;

if (settings == null) {
	throw new Error('`settings.scholieren` is required but is null or undefined.');
}

Scholieren = {
	getClasses: function () {
		var options = {}, callback;
		for (var i = 0; i < arguments.length; i++) {
			var arg = arguments[i];
			if (typeof arg === 'object') {
				options = arg;
			} else if (typeof arg === 'function') {
				callback = arg;
			}
		}

		for (var key in options) {
			if (options[key] != null) {
				var optionsKey = key;
				break;
			}
		}

		HTTP.post('http://api.scholieren.com/', {
			params: {
				'client_id': settings['client_id'],
				'client_pw': settings['client_pw'],
				'request': 'subjects',
				'by_item': optionsKey || '',
				'by_data': options[optionsKey] || '',
			},
		}, function (error, result) {
			if (error) {
				callback(error, null);
			} else {
				try {
					callback(null, JSON.parse(result.content).subjects);
				} catch (error) {
					callback(error, null);
				}
			}
		});
	},

	getBooks: function () {
		var options = {}, callback;
		for (var i = 0; i < arguments.length; i++) {
			var arg = arguments[i];
			if (typeof arg === 'object') {
				options = arg;
			} else if (typeof arg === 'function') {
				callback = arg;
			}
		}

		for (var key in options) {
			if (options[key] != null) {
				var optionsKey = key;
				break;
			}
		}

		HTTP.post('http://api.scholieren.com/', {
			params: {
				'client_id': settings['client_id'],
				'client_pw': settings['client_pw'],
				'request': 'methods',
				'by_item': optionsKey || '',
				'by_data': options[optionsKey] || '',
			},
		}, function (error, result) {
			if (error) {
				callback(error, null);
			} else {
				try {
					callback(
						null,
						JSON.parse(result.content)
							.methods
							.map(function (book) {
								return {
									id: book.id,
									classId: book.vakid,
									title: book.name,
								};
							})
					);
				} catch (error) {
					callback(error, null);
				}
			}
		});
	},
};
