var selected = null;
var helpEngine = null;

var searchQuery = new ReactiveVar("");

var searching = new ReactiveVar(false);
var loading = new ReactiveVar(false);
var searchResults = new ReactiveVar([]);

Template.help.events({
	"keyup input": function (event) {
		var trimmed = event.target.value.trim()
		searchQuery.set(trimmed);

		if (event.which === 13) {
			Router.go("helpArticle", selected);

		} else if (trimmed.length === 0) {
			event.target.value = "";
			searching.set(false);

		} else {
			searching.set(true);
			loading.set(true);

			helpEngine.get(trimmed, function (res) {
				searchResults.set(res);
				loading.set(false);
			})

		}
	}
});

Template.help.helpers({
	searching: function () { return searching.get(); },
	loading: function () { return loading.get(); },
	results: function () { return searchResults.get(); }
});

Template.help.rendered = function () {
	helpEngine = new Bloodhound({
		name: "helpEntries",
		datumTokenizer: Bloodhound.tokenizers.obj.whitespace("title", "summary"),
		queryTokenizer: Bloodhound.tokenizers.whitespace,
		local: HelpEntries.find().fetch()
	});
	helpEngine.initialize();

	this.autorun(function () {
		Meteor.subscribe("helpEntries");

		helpEngine.clear();
		helpEngine.add(HelpEntries.find().fetch());
	});
};
