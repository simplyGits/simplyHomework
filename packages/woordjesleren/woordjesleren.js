'use strict';

var $ = cheerio;
var urls = {
	categories: 'http://www.woordjesleren.nl/api/select_categories.php',
	books: 'http://www.woordjesleren.nl/api/select_books.php?category=',
	listsByBook: 'http://www.woordjesleren.nl/api/select_lists.php?book=',
	listsByUser: 'http://www.woordjesleren.nl/api/select_lists_by_poster.php?poster=',
	list: 'http://www.woordjesleren.nl/api/select_list.php?list=',
};

WoordjesLeren = {};

WoordjesLeren.getClasses = function () {
	var result = HTTP.get(urls.categories).content;
	return $(result).find('categories').contents().toArray().map(function (n) {
		return {
			id: parseInt(n.attribs.id, 10),
			name: n.firstChild.data.trim(),
		};
	});
};

WoordjesLeren.getBooks = function (classId) {
	var result = HTTP.get(urls.books + classId).content;
	return $(result).find('books').contents().toArray().map(function (n) {
		return {
			id: parseInt(n.attribs.id, 10),
			name: n.firstChild.data.trim(),
			listCount: parseInt(n.attribs['list_count'], 10),
		};
	});
};

WoordjesLeren.getListsByBook = function (bookId) {
	var result = HTTP.get(urls.listsByBook + bookId).content;
	return $(result).find('lists').contents().toArray().map(function (n) {
		return {
			id: parseInt(n.attribs.id, 10),
			name: n.firstChild.data.trim(),
		};
	});
};

WoordjesLeren.getListsByUser = function (userId) {
	var result = HTTP.get(urls.listsByUser + userId).content;
	return $(result).find('lists').contents().toArray().map(function (n) {
		return {
			id: parseInt(n.attribs.id, 10),
			name: n.firstChild.data.trim(),
		};
	});
};

WoordjesLeren.getList = function (listId) {
	var parseDate = function (str) {
		var splitted = str.split('-');
		return new Date(splitted[2], splitted[1] - 1, splitted[0]);
	};

	var result = HTTP.get(urls.list + listId).content;
	var node =  $(result).find('list')[0]

	var rows = node.firstChild.data.trim().split('\n');
	var content = rows.map(function (row) {
		return row.split(/ ?= ?/);
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
