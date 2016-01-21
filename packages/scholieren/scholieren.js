/* global Scholieren:true */
'use strict';

// TODO: make this an external service

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

Search.provide('scholieren', function ({ query, user, classes, keywords }) {
	if (!_.contains(keywords, 'report')) {
		return [];
	} else {
		let res = [];

		classes.forEach(function (c) {
			const classInfo = _.find(getClassInfos(user._id), { id: c._id });

			const book = Books.findOne(classInfo.bookId);
			const bookName = (book && book.title) || '';
			const q = `${normalizeClassName(c.name)} ${bookName} ${query}`;

			const reports = _(Scholieren.getReports(q))
				.filter(function (item) {
					const reg = /^.+\(([^\)]+)\)$/;
					const match = reg.exec(item.title);
					return !match || match[1].toLowerCase() === bookName.toLowerCase();
				})
				.map(function (item) {
					item.title = item.title.replace(/\([^\)]+\)$/, '');
					return _.extend(item, {
						type: 'report',
						filtered: true,
					});
				})
				.value();

			res = res.concat(reports);
		});

		return res;
	}
});
