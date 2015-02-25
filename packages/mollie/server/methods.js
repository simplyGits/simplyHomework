var mollie = Npm.require("mollie-api-node");
var Future = Npm.require("fibers/future");
var client = null;

var settings = Meteor.settings && Meteor.settings.mollie;
if (settings == null || settings.apiKey == null) {
	console.log(
		"Settings (and settings.apiKey) is required!\n" +
		"See GitHub repo for more info."
	);
} else {
	client = new mollie.API.Client();
	client.setApiKey(settings.apiKey);

	Meteor.methods({
		"_mollieMakePayement": function (options) {
			if (this.connection != null && !settings.allowClient)
				throw new Meteor.Error("forbidden", "Clients aren't allowed to make requests.");

			if (options == null) throw new Meteor.Error("bad-request", "Options parameter required.");
			if (client == null) throw new Meteor.Error("missing-client", "Mollie client wasn't created, did you specify your API key in your settings.json?")

			var fut = new Future();
			client.payments.create(options, function (payement) {
				if (payement) fut.return(payement);
				else fut.throw(new Error("Error while making payement."));
			});
			return fut.wait();
		},

		"_mollieGetPayement": function (id) {
			if (this.connection != null && !settings.allowClient)
				throw new Meteor.Error("forbidden", "Clients aren't allowed to make requests.");

			if (id == null) throw new Meteor.Error("bad-request", "id parameter required.");
			if (client == null) throw new Meteor.Error("missing-client", "Mollie client wasn't created, did you specify your API key in your settings.json?")

			var fut = new Future();
			client.payments.get(id, function (payement) {
				if (payement) fut.return(payement);
				else fut.throw(new Error("No payement found."));
			});
			return fut.wait();
		}
	});
}
