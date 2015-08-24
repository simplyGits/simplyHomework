var mollie = Npm.require('mollie-api-node');
var Future = Npm.require('fibers/future');
var client = null;
var Payements = new Mongo.Collection('payements');

var settings = Meteor.settings && Meteor.settings.mollie;
if (settings == null || settings.apiKey == null) {
	console.error(
		'========================= meteor-mollie =======================\n' +
		'\tSettings.mollie (and settings.mollie.apiKey) is required!\n' +
		'\tSee GitHub repo for more info.\n' +
		'==============================================================='
	);
} else {
	client = new mollie.API.Client();
	client.setApiKey(settings.apiKey);

	Meteor.methods({
		'mollie-makePayement': function (options) {
			if (this.connection != null && !settings.allowClient)
				throw new Meteor.Error('forbidden', "Clients aren't allowed to make requests.");

			if (options == null) throw new Meteor.Error('bad-request', 'Options parameter required.');
			if (client == null) throw new Meteor.Error('missing-client', "Mollie client wasn't created, did you specify your API key in your settings.json?")

			var fut = new Future();
			client.payments.create(options, function (payement) {
				if (payement) fut.return(payement);
				else fut.throw(new Error('Error while making payement.'));
			});
			return fut.wait();
		},

		'mollie-getPayement': function (id) {
			this.unblock();

			if (this.connection != null && !settings.allowClient)
				throw new Meteor.Error('forbidden', "Clients aren't allowed to make requests.");

			if (id == null) throw new Meteor.Error('bad-request', 'id parameter required.');
			if (client == null) throw new Meteor.Error('missing-client', "Mollie client wasn't created, did you specify your API key in your settings.json?")

			var fut = new Future();
			client.payments.get(id, function (payement) {
				if (payement) fut.return(payement);
				else fut.throw(new Error('No payement found.'));
			});
			return fut.wait();
		}
	});
}
