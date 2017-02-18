/* global Scholieren:true, getClassInfos:true, Books:true,
   normalizeClassName:true */
import url from 'url';

const settings = Meteor.settings && Meteor.settings.scholieren;

Scholieren = {
	name: 'scholieren',
	friendlyName: 'Scholieren.com',
	loginNeeded: false,

	getClasses(options) {
		options = options || {};

		let optionsKey = undefined;
		for (const key in options) {
			if (options[key] != null) {
				optionsKey = key;
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

	getBooks(options) {
		options = options || {};

		let optionsKey = undefined;
		for (const key in options) {
			if (options[key] != null) {
				optionsKey = key;
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

	getReports(query) {
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
			const r = _.merge(...report);

			const parsed = url.parse(r.url);
			parsed.host = parsed.hostname = 'www.scholieren.nl';

			const verified = r.url.includes('zekerwetengoed');
			const rating = verified ?
				Infinity : // ¯\_(ツ)_/¯
				Number.parseFloat(r.rating, 10);

			return {
				title: r.titel,
				url: url.format(parsed),
				verified,
				rating,
			};
		});
	},
};

if (settings != null && Package.search != null) {
	Package.search.Search.provide('scholieren', function ({ query, user, classes, keywords }) {
		if (!_.contains(keywords, 'report')) {
			return [];
		}

		let res = [];
		const classInfos = getClassInfos(user._id);

		for (const c of classes) {
			const classInfo = _.find(classInfos, { id: c._id });

			const book = Books.findOne(classInfo.bookId);
			const bookName = (book && book.title) || '';
			const q = `${normalizeClassName(c.name)} ${bookName} ${query}`;

			const reports = _.chain(Scholieren.getReports(q))
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
		}

		return res;
	});
}

if (settings == null) {
	console.warn('`settings.scholieren` is null or undefined, scholieren package will be disabled.');
	Scholieren = {};
}
