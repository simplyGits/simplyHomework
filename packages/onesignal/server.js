const APP_ID = Meteor.settings.public.onesignal.appId;
const API_KEY = Meteor.settings.onesignal.apiKey;
const API_URL = 'https://onesignal.com/api/v1';

import { HTTP } from 'meteor/http';

/**
 * @method sendNotification
 * @param {String|String[]} userIds
 * @param {String} message
 * @param {Object} [options={}]
 * @return {String[]} Array containing the IDs of the users where the
 * notification was sent to.
 */
export function sendNotification (userIds, message, options = {}) {
	if (!Array.isArray(userIds)) {
		userIds = [ userIds ];
	}

	check(userIds, [String]);
	check(message, String);
	check(options, Object);

	// REVIEW: add check for push notifications options here?
	// Useful if we have a global push notification opt-out.
	const users = Meteor.users.find({
		_id: {
			$in: userIds,
		},
		'onesignal.userIds': {
			$exists: true,
			$ne: [],
		},
	}).fetch();

	if (users.length > 0) {
		const onesignalIds = users
			.map(user => user.onesignal.userIds)
			.reduce((a, b) => a.concat(b));

		const langObj = (val) => val != null ? { en: val } : val;

		HTTP.post(`${API_URL}/notifications`, {
			headers: {
				'Authorization': `Basic ${API_KEY}`,
			},
			data: {
				app_id: APP_ID,

				headings: langObj(options.title),
				contents: langObj(message),

				isAnyWeb: true,
				include_player_ids: onesignalIds,
				web_buttons: options.buttons,

				chrome_web_icon: options.picture,
				firefox_icon: options.picture,

				url: options.url,
				ttl: options.ttl,
				data: options.data,
			},
		});
	}

	return users.map(user => user._id);
}

Meteor.methods({
	'onesignal_addUserId': function (osUserId) {
		check(osUserId, Match.Optional(String));

		Meteor.users.update({
			_id: this.userId,
		}, {
			$addToSet: {
				'onesignal.userIds': osUserId,
			},
		});
	},
})
