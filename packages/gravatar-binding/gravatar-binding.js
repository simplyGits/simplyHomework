/*
 * simplyHomework binding to Gravatar.
 * @author simply
 * @module gravatar-binding
 */

(function (Future, request) {
	"use strict";

	GravatarBinding = {
		name: "gravatar",
		friendlyName: "Gravatar",
		loginNeeded: false,

		/*
		 * @method createData
		 * @param userId {String} The ID of the user to save the info to.
		 * @param {Boolean|undefined}
		 */
		createData: function (userId) {
			var user = Meteor.users.findOne(userId);
			var md5 = CryptoJS.MD5(user.emails[0].address).toString();

			var response;
			try {
				response = Meteor.wrapAsync(request.get)({
					url: 'https://www.gravatar.com/avatar/' + md5 + '?d=identicon&d=404&s=1'
				});
			} catch (e) {
				return undefined;
			}

			var pictureUrl = 'https://www.gravatar.com/avatar/' + md5 + '?d=identicon&r=PG';
			var obj = {
				url: pictureUrl,
				has: response.statusCode !== 404
			}

			GravatarBinding.storedInfo(userId, obj);
			return obj.has;
		},

		getProfileData: function (userId) {
			check(userId, String);
			var info = GravatarBinding.storedInfo(userId);

			return {
				picture: info.has ? info.url : undefined
			}
		}
	};
})(Npm.require("fibers/future"), Meteor.npmRequire("request"));
