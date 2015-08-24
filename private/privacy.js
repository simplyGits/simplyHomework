#!/usr/bin/env node

'use strict';

var fs = require('fs');
var path = require('path');
var marked = require('./marked.js');

function fromCurrentDir (str) {
	return path.join(__dirname, str);
}

function readLocalFile (name) {
	return fs.readFileSync(fromCurrentDir(name), 'utf8');
}

function makeTemplate (template) {
	return function (data) {
		return template.replace(/<%=(.+?)%>/g, function (match, content) {
			return data[content.trim()];
		});
	};
}

var dest = fromCurrentDir('../public/privacy.html');
var template = makeTemplate(readLocalFile('privacy.template.html'));
var res = template({
	content: marked(readLocalFile('privacy.md')),
});
fs.writeFileSync(dest, res);
