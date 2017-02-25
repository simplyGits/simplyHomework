// Code halfstolen from https://github.com/stubailo/meteor-katex
Package.describe({
	name: 'simply:katex',
	version: '0.6.0',
	summary: 'The fastest math typesetting library for the web.',
	git: '',
	documentation: 'README.md',
});

Package.onUse(function(api) {
	api.versionsFrom('1.1.0.3');
	api.use('ecmascript');
	api.use('templating', 'client', { weak: true });

	api.addFiles('dist/katex.min.css');
	api.addFiles('fonts-override.css', 'client');
	api.addAssets([
		'dist/fonts/KaTeX_AMS-Regular.eot',
		'dist/fonts/KaTeX_AMS-Regular.ttf',
		'dist/fonts/KaTeX_AMS-Regular.woff',
		'dist/fonts/KaTeX_AMS-Regular.woff2',
		'dist/fonts/KaTeX_Caligraphic-Bold.eot',
		'dist/fonts/KaTeX_Caligraphic-Bold.ttf',
		'dist/fonts/KaTeX_Caligraphic-Bold.woff',
		'dist/fonts/KaTeX_Caligraphic-Bold.woff2',
		'dist/fonts/KaTeX_Caligraphic-Regular.eot',
		'dist/fonts/KaTeX_Caligraphic-Regular.ttf',
		'dist/fonts/KaTeX_Caligraphic-Regular.woff',
		'dist/fonts/KaTeX_Caligraphic-Regular.woff2',
		'dist/fonts/KaTeX_Fraktur-Bold.eot',
		'dist/fonts/KaTeX_Fraktur-Bold.ttf',
		'dist/fonts/KaTeX_Fraktur-Bold.woff',
		'dist/fonts/KaTeX_Fraktur-Bold.woff2',
		'dist/fonts/KaTeX_Fraktur-Regular.eot',
		'dist/fonts/KaTeX_Fraktur-Regular.ttf',
		'dist/fonts/KaTeX_Fraktur-Regular.woff',
		'dist/fonts/KaTeX_Fraktur-Regular.woff2',
		'dist/fonts/KaTeX_Main-Bold.eot',
		'dist/fonts/KaTeX_Main-Bold.ttf',
		'dist/fonts/KaTeX_Main-Bold.woff',
		'dist/fonts/KaTeX_Main-Bold.woff2',
		'dist/fonts/KaTeX_Main-Italic.eot',
		'dist/fonts/KaTeX_Main-Italic.ttf',
		'dist/fonts/KaTeX_Main-Italic.woff',
		'dist/fonts/KaTeX_Main-Italic.woff2',
		'dist/fonts/KaTeX_Main-Regular.eot',
		'dist/fonts/KaTeX_Main-Regular.ttf',
		'dist/fonts/KaTeX_Main-Regular.woff',
		'dist/fonts/KaTeX_Main-Regular.woff2',
		'dist/fonts/KaTeX_Math-BoldItalic.eot',
		'dist/fonts/KaTeX_Math-BoldItalic.ttf',
		'dist/fonts/KaTeX_Math-BoldItalic.woff',
		'dist/fonts/KaTeX_Math-BoldItalic.woff2',
		'dist/fonts/KaTeX_Math-Italic.eot',
		'dist/fonts/KaTeX_Math-Italic.ttf',
		'dist/fonts/KaTeX_Math-Italic.woff',
		'dist/fonts/KaTeX_Math-Italic.woff2',
		'dist/fonts/KaTeX_Math-Regular.eot',
		'dist/fonts/KaTeX_Math-Regular.ttf',
		'dist/fonts/KaTeX_Math-Regular.woff',
		'dist/fonts/KaTeX_Math-Regular.woff2',
		'dist/fonts/KaTeX_SansSerif-Bold.eot',
		'dist/fonts/KaTeX_SansSerif-Bold.ttf',
		'dist/fonts/KaTeX_SansSerif-Bold.woff',
		'dist/fonts/KaTeX_SansSerif-Bold.woff2',
		'dist/fonts/KaTeX_SansSerif-Italic.eot',
		'dist/fonts/KaTeX_SansSerif-Italic.ttf',
		'dist/fonts/KaTeX_SansSerif-Italic.woff',
		'dist/fonts/KaTeX_SansSerif-Italic.woff2',
		'dist/fonts/KaTeX_SansSerif-Regular.eot',
		'dist/fonts/KaTeX_SansSerif-Regular.ttf',
		'dist/fonts/KaTeX_SansSerif-Regular.woff',
		'dist/fonts/KaTeX_SansSerif-Regular.woff2',
		'dist/fonts/KaTeX_Script-Regular.eot',
		'dist/fonts/KaTeX_Script-Regular.ttf',
		'dist/fonts/KaTeX_Script-Regular.woff',
		'dist/fonts/KaTeX_Script-Regular.woff2',
		'dist/fonts/KaTeX_Size1-Regular.eot',
		'dist/fonts/KaTeX_Size1-Regular.ttf',
		'dist/fonts/KaTeX_Size1-Regular.woff',
		'dist/fonts/KaTeX_Size1-Regular.woff2',
		'dist/fonts/KaTeX_Size2-Regular.eot',
		'dist/fonts/KaTeX_Size2-Regular.ttf',
		'dist/fonts/KaTeX_Size2-Regular.woff',
		'dist/fonts/KaTeX_Size2-Regular.woff2',
		'dist/fonts/KaTeX_Size3-Regular.eot',
		'dist/fonts/KaTeX_Size3-Regular.ttf',
		'dist/fonts/KaTeX_Size3-Regular.woff',
		'dist/fonts/KaTeX_Size3-Regular.woff2',
		'dist/fonts/KaTeX_Size4-Regular.eot',
		'dist/fonts/KaTeX_Size4-Regular.ttf',
		'dist/fonts/KaTeX_Size4-Regular.woff',
		'dist/fonts/KaTeX_Size4-Regular.woff2',
		'dist/fonts/KaTeX_Typewriter-Regular.eot',
		'dist/fonts/KaTeX_Typewriter-Regular.ttf',
		'dist/fonts/KaTeX_Typewriter-Regular.woff',
		'dist/fonts/KaTeX_Typewriter-Regular.woff2',
	], 'client');

	// api.mainModule('client.js', 'client');
	api.mainModule('server.js', 'server');
});

Package.onTest(function(api) {
	api.use('tinytest');
	api.use('katex');
	api.addFiles('katex-tests.js');
});
