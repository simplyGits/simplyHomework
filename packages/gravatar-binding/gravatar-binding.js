/* global GravatarBinding, ExternalServicesConnector */

(function (Future, request) {
	'use strict';

	/**
	 * @method checkGravatarAvailable
	 * @param {String} md5 md5 hash of the email to check.
	 * @return {Boolean} Whether or not there is a gravatar for the given `md5`.
	 */
	function checkGravatarAvailable (md5) {
		return Meteor.wrapAsync(request.get)({
			url: 'https://www.gravatar.com/avatar/' + md5 + '?d=identicon&d=404&s=1',
		}).statusCode !== 404;
	}

	GravatarBinding.createData = function () {
		// An user can always create a gravatar and checking is pretty
		// cheap, so we wan't to check every time for a gravatar when we
		// need it.
		return true;
	};

	GravatarBinding.getProfileData = function (userId) {
		check(userId, String);
		var user = Meteor.users.findOne(userId);
		var md5 = CryptoJS.MD5(user.emails[0].address).toString();

		var has = checkGravatarAvailable(md5);
		var pictureUrl = 'https://www.gravatar.com/avatar/' + md5 + '?d=identicon&r=PG';

		return {
			picture: has ? pictureUrl : undefined,
		};
	};
})(Npm.require('fibers/future'), Npm.require('request'));
