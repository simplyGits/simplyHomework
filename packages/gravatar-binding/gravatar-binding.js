/* global GravatarBinding */

import request from 'request'
import md5 from 'md5'

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

/**
 * @method createData
 * @param {String} userId
 */
GravatarBinding.createData = function (userId) {
	// An user can always create a gravatar and checking is pretty
	// cheap, so we will just mark the service active, and check every time for
	// a gravatar when we need it.
	GravatarBinding.active(userId, true);
};

/**
 * @method getProfileData
 * @param {String} userId
 * @return {String|undefined}
 */
GravatarBinding.getProfileData = function (userId) {
	check(userId, String);
	const user = Meteor.users.findOne(userId);
	const hash = md5(user.emails[0].address);

	const has = checkGravatarAvailable(hash);
	const pictureUrl = `https://www.gravatar.com/avatar/${hash}?d=identicon&r=PG`;

	return {
		picture: has ? pictureUrl : undefined,
	};
};
