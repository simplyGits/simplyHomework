require('./dist/OneSignalSDK.js');
/* global OneSignal */

OneSignal.push(['init', {
	appId: '627db6f5-0b35-4546-83f0-9818878159fe',
	autoRegister: false,
	persistNotification: false,
	notifyButton: {
		enable: false,
	},
	welcomeNotification: {
		disable: true,
	},
}]);

OneSignal.push(function () {
	OneSignal.on('subscriptionChange', function (isSubscribed) {
		const promise = isSubscribed ?
			OneSignal.getUserId() :
			Promise.resolve(undefined);

		promise.then(userId => {
			Meteor.call('onesignal_addUserId', userId);
		});
	});
});

export function register () {
	OneSignal.push([ 'registerForPushNotifications' ]);
}

export function isEnabled () {
	return new Promise(resolve => {
		OneSignal.isPushNotificationsEnabled(resolve);
	})
}

export function isSupported () {
	return OneSignal.isPushNotificationsSupported();
}
