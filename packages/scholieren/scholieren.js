/* global Scholieren:true */
'use strict';

const settings = Meteor.settings && Meteor.settings.scholieren;

if (settings == null) {
	throw new Error('`settings.scholieren` is required but is null or undefined.');
}

Scholieren = {
	name: 'scholieren',
	friendlyName: 'Scholieren.com',
	loginNeeded: false,

	getClasses: function (options) {
		options = options || {};

		for (const key in options) {
			if (options[key] != null) {
				var optionsKey = key;
				break;
			}
		}

		const result = HTTP.post('http://api.scholieren.com/', {
			params: {
				'client_id': settings['client_id'],
				'client_pw': settings['client_pw'],
				'request': 'subjects',
				'by_item': optionsKey || '',
				'by_data': options[optionsKey] || '',
			},
		});

		return JSON.parse(result.content).subjects;
	},

	getBooks: function (options) {
		options = options || {};

		for (const key in options) {
			if (options[key] != null) {
				var optionsKey = key;
				break;
			}
		}

		const result = HTTP.post('http://api.scholieren.com/', {
			params: {
				'client_id': settings['client_id'],
				'client_pw': settings['client_pw'],
				'request': 'methods',
				'by_item': optionsKey || '',
				'by_data': options[optionsKey] || '',
			},
		});

		return JSON.parse(result.content).methods.map(function (book) {
			return {
				id: book.id,
				classId: book.vakid,
				title: book.name,
			};
		});
	},

	getReports: function (query) {
		const result = HTTP.post('http://api.scholieren.com/', {
			params: {
				'client_id': settings['client_id'],
				'client_pw': settings['client_pw'],
				'request': 'reports',
				'by_item': 'terms',
				'by_data': query,
			},
		});
		if (!result.content.trim().length) {
			return [];
		}

		const reports = JSON.parse(result.content).reports || [];
		return reports.map(function (report) {
			const res = {}
			report.forEach(function (obj) {
				const pair = _.pairs(obj)[0];
				res[pair[0]] = pair[1];
			});
			return {
				title: res.titel,
				url: res.url,
				rating: res.rating,
			};
		});
	},
};
