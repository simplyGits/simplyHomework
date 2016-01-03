/*
 * simplyHomework binding to WRTS.
 * @author simply
 * @module wrts-binding
 */

/* global WrtsBinding:true */
'use strict';

var Future = Npm.require('fibers/future');
var Wrts = Npm.require('wrts');

WrtsBinding = {
	name: 'wrts',
	friendlyName: 'WRTS',
	loginNeeded: true,
	createData: function (email, password, userId) {
		check(email, String);
		check(password, String);
		check(userId, String);

		if (
			email.length === 0 ||
			password.length === 0
		) {
			return false;
		}

		WrtsBinding.storedInfo(userId, {
			credentials: {
				email: email,
				password: password,
			},
		});

		try {
			getWrtsObject(userId);
		} catch (e) {
			WrtsBinding.storedInfo(userId, null);
		}
	},
};

function getWrtsObject (userId) {
	check(userId, String);

	var fut = new Future();
	var data = WrtsBinding.storedInfo(userId);
	if (_.isEmpty(data)) {
		throw new Error('No credentials found.');
	} else {
		Wrts(data.credentials.email, data.credentials.password, fut.resolver());
	}

	return fut.wait();
}

WrtsBinding.getProfileData = function (userId) {
	check(userId, String);

	var userInfo = Meteor.wrapAsync(getWrtsObject(userId).getUserInfo)();
	return {
		nameInfo: {
			firstName: userInfo.first_name,
			lastName: userInfo.last_name,
		},
		birthDate: userInfo.last_seen_on,
	};
};
