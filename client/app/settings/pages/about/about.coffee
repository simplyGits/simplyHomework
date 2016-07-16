info = require('/imports/version.js').default

Template['settings_page_about'].helpers
	commit: info.commit.substr 0, 7
	buildDate: info.buildDate
