/* global GravatarBinding, CryptoJS */

import request from 'request'

/**
 * @method checkGravatarAvailable
 * @param {String} md5 md5 hash of the email to check.
 * @return {Boolean} Whether or not there is a gravatar for the given `md5`.
 */
function checkGravatarAvailable (md5) {
	return Meteor.wrapAsync(request.get)({
		url: `https://www.gravatar.com/avatar/${md5}?d=identicon&d=404&s=1`,
	}).statusCode !== 404;
}

GravatarBinding.createData = function () {
	// An user can always create a gravatar and checking is pretty
	// cheap, so we want to check every time for a gravatar when we
	// need it.
	return true;
};

GravatarBinding.getProfileData = function (userId) {
	check(userId, String);
	const user = Meteor.users.findOne(userId);
	const md5 = CryptoJS.MD5(user.emails[0].address).toString();

	const has = checkGravatarAvailable(md5);
	const pictureUrl = 'https://www.gravatar.com/avatar/' + md5 + '?d=identicon&r=PG';

	return {
		picture: has ? pictureUrl : undefined,
	};
};
