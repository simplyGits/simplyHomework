/* global cheerio, WoordjesLeren:true, Books:true, Search:true */
'use strict';

// TODO: make this an external service

const $ = cheerio;
const urls = {
	categories: 'http://www.woordjesleren.nl/api/select_categories.php',
	books: 'http://www.woordjesleren.nl/api/select_books.php',
	listsByBook: 'http://www.woordjesleren.nl/api/select_lists.php',
	listsByUser: 'http://www.woordjesleren.nl/api/select_lists_by_poster.php',
	list: 'http://www.woordjesleren.nl/api/select_list.php',
	search: 'http://www.woordjesleren.nl/api/search.php',
};

WoordjesLeren = {
	name: 'woordjesleren',
	friendlyName: 'woordjesleren.nl',
	loginNeeded: false,
};

WoordjesLeren.getClasses = function () {
	const result = HTTP.get(urls.categories).content;
	return $(result).find('categories').contents().toArray().map(function (n) {
		return {
			id: parseInt(n.attribs.id, 10),
			name: n.firstChild.data.trim(),
		};
	});
};

WoordjesLeren.getBooks = function (classId) {
	const result = HTTP.get(urls.books, {
		params: {
			category: classId,
		},
	}).content;

	return $(result).find('books').contents().toArray().map(function (n) {
		return {
			id: parseInt(n.attribs.id, 10),
			title: n.firstChild.data.trim(),
			listCount: parseInt(n.attribs['list_count'], 10),
		};
	});
};

WoordjesLeren.getListsByBook = function (options) {
	if (options.bookId == null) {
		throw new Error('options.bookId is required');
	}

	const result = HTTP.get(urls.listsByBook, {
		params: {
			book: options.bookId,
			part: options.part || '',
			year: options.year || '',
			date: options.date || '',
			schooltype: options.schooltype || '',
		},
	}).content;
	return $(result).find('lists').contents().toArray().map(function (n) {
		return {
			id: parseInt(n.attribs.id, 10),
			name: n.firstChild.data.trim(),
		};
	});
};

WoordjesLeren.getListsByUser = function (userId) {
	const result = HTTP.get(urls.listsByUser, {
		params: {
			poster: userId,
		},
	}).content;

	return $(result).find('lists').contents().toArray().map(function (n) {
		return {
			id: parseInt(n.attribs.id, 10),
			name: n.firstChild.data.trim(),
		};
	});
};

WoordjesLeren.getList = function (listId) {
	const parseDate = function (str) {
		const splitted = str.split('-');
		return new Date(splitted[2], splitted[1] - 1, splitted[0]);
	};

	const result = HTTP.get(urls.list, {
		params: {
			list: listId,
		},
	}).content;
	const node =  $(result).find('list')[0]

	const rows = node.firstChild.data.split('\n');
	const content = rows.map(function (row) {
		return row.replace(/{[^}]*}/g, '').trim().split(/ ?= ?/);
	});

	return {
		id: parseInt(node.attribs.id, 10),
		poster: node.attribs['poster_name'].trim(),
		date: parseDate(node.attribs['upload_dt_formatted']),
		courseType: node.attribs['schooltype_name'].trim(),
		year: parseInt(node.attribs.year, 10),
		content: content,
	};
};

WoordjesLeren.search = function (query) {
	query = encodeURIComponent(query);
	const result = HTTP.get(urls.search, {
		params: {
			q: query,
		},
	}).content;
	return $(result).find('searchitems').contents().toArray().map(function (n) {
		const id = parseInt(n.attribs.id, 10);
		return {
			type: n.attribs.type,
			id: id >= 0 ? id : undefined,
			name: n.firstChild.data.trim(),
		};
	});
};

Search.provide('woordjesleren', function ({ user, classes, keywords }) {
	let res = [];

	if (_.contains(keywords, 'vocab')) {
		classes.forEach(function (c) {
			const { year, schoolVariant } = user.profile.courseInfo;
			const classInfo = _.find(user.classInfos, { id: c._id });
			const book = Books.findOne(classInfo.bookId);

			if (_.has(book, 'externalInfo.woordjesleren')) {
				const lists = WoordjesLeren.getListsByBook({
					year: year,
					schooltype: schoolVariant,
					bookId: book.externalInfo.woordjesleren,
				}).map(function (item) {
					return {
						type: 'wordlist',
						id: item.id,
						title: item.name,
						url: `https://www.woordjesleren.nl/questions.php?chapter=${item.id}`,
					};
				});
				res = res.concat(lists);
			}
		});
	}

	return res;
});
