if (!Meteor.settings.public.onesignal) {
	console.warn('`settings.public.onesignal` is null or undefined, onesignal package will be disabled.');
} else if (Meteor.isClient) {
	module.exports = require('./client.js');
} else if (Meteor.isServer) {
	module.exports = require('./server.js');
}
