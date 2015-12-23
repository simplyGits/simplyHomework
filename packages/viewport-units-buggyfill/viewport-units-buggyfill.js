Meteor.startup(function () {
	window.viewportUnitsBuggyfill.init({
		hacks: window.viewportUnitsBuggyfillHacks,
	});
});
