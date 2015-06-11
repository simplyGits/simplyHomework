(function () {
	"use strict";

	var m = Magister;
	var Future = Npm.require("fibers/future");

	var SESSIONID_INVALIDATE_TIME = 1000*60*60*24; // 24h
	var ONLY_RECENT_LIMIT = 1000*60*60*24*6; // 6 days

	/*
	 * A simplyHomework binding to Magister.
	 * @class MagisterBinding
	 * @static
	 */
	MagisterBinding = {
		name: "magister",
		createData: function (schoolurl, username, password, userId) {
			check(schoolurl, String);
			check(username, String);
			check(password, String);
			check(userId, Match.Optional(String));

			MagisterBinding.storedInfo(userId, {
				credentials: {
					schoolurl: schoolurl,
					username: username,
					password: password
				}
			});
		}
	};

	/**
	 * Gets a magister object for the given `userId`.
	 * @method getMagisterObject
	 * @private
	 * @param userId {String} The ID of the user to get a Magister object for.
	 * @return {Magister} A Magister object for the given `userId`.
	 */
	function getMagisterObject (userId) {
		check(userId, String);

		var fut = new Future();
		var data = MagisterBinding.storedInfo(userId);
		if (_.isEmpty(data)) {
			throw new Error("No credentials found.");
		} else {
			// // We invalidate the sessionId after SESSIONID_INVALIDATE_TIME.
			// var useSessionId = data.lastLogin &&
			// 	_.now() - data.lastLogin.time.getTime() <= SESSIONID_INVALIDATE_TIME;

			// Currently not invalidating sessionIds, since it's unknown when
			// they retire at Magister's servers. Maybe they're even infinite.
			var useSessionId = !_.isEmpty(data.lastLogin);

			var magister = new m.Magister({
				school: {
					url: data.credentials.schoolurl
				},
				username: data.credentials.username,
				password: data.credentials.password,
				sessionId: useSessionId ? data.lastLogin.sessionId : null
			});

			console.log({ // debug info
				magister: magister,
				useSessionId: useSessionId
			});

			if (!useSessionId) { // Update login info
				MagisterBinding.storedInfo(userId, {
					lastLogin: {
						time: new Date(),
						sessionId: magister._sessionId
					}
				});
			}

			magister.ready(function (err) {
				if (err) {
					fut.throw(err);
				} else {
					fut.return(magister);
				}
			});

			return fut.wait();
		}
	}

	/*
	 * Gets the current course for the given Magister object.
	 * @method getCurrentCourse
	 * @private
	 * @param magister {Magister} The Magister object to get the course from.
	 * @return {Course} The current course.
	 */
	function getCurrentCourse (magister) {
		var fut = new Future();
		magister.currentCourse(fut.resolver());
		return fut.wait();
	}

	/*
	 * Get the grades for the given userId from Magister.
	 * @method getGrades
	 * @param userId {String} The ID of the user to get the grades from.
	 * @return {StoredGrade[]} The grades as a grade array.
	 */
	MagisterBinding.getGrades = function (userId, options) {
		check(userId, String);
		check(options, Match.Optional(Object));

		var fut = new Future();

		var magister = getMagisterObject(userId);
		var user = Meteor.users.findOne(userId);
		var lastUpdateTime = user.lastGradeUpdateTime;
		var onlyRecent = options.onlyRecent ||
			lastUpdateTime && (_.now() - lastUpdateTime.getTime() <= ONLY_RECENT_LIMIT);

		console.log("getGrades -> magister", magister);

		var course = getCurrentCourse(magister);
		course.grades(false, false, onlyRecent, function (e, r) {
			if (e) {
				fut.throw(e);
			} else {
				var result = new Array(r.length);
				var futs = [];

				r.forEach(function (g, i) {
					var stored = StoredGrades.findOne({
						externalId: g.id()
					});

					if (stored) {
						result[i] = stored;
					} else {
						var gradeFut = new Future();
						futs.push(gradeFut);

						g.fillGrade(function (e, r) {
							if (e) {
								gradeFut.throw(e);
							} else  {
								var weight = g.counts() ? g.weight() : 0;
								var classId = _.filter(user.classInfos, function (i) {
									return i.createdBy == MagisterBinding.name &&
										i.externalId === g.class().id();
								}).id;

								var storedGrade = new StoredGrade(
									gradeConverter(g.grade()),
									weight,
									g.dateFilledIn(),
									classId,
									userId
								);

								storedGrade.externalId = g.id();
								storedGrade.description = g.description().trim();
								storedGrade.passed = g.passed() || storedGrade.passed;
								storedGrade.isEnd = g.type().type() === 2;

								result[i] = storedGrade;
								gradeFut.return();
							}
						});
					}
				});

				for(var i = 0; i < futs.length; i++) futs[i].wait();
				fut.return(result);
			}
		});

		return fut.wait();
	};

	/*
	 * Get the studyUtil for the given userId from Magister.
	 * @method getStudyUtils
	 * @param userId {String} The ID of the user to get the studyUtil from.
	 * @param [callback] {Function} An optional callback.
	 * 	@param [callback.error] {Object} The error, if any.
	 * 	@param [callback.result] {StudyUtil[]} The result, if there is no error.
	 * @return {ReactiveVar<StudyUtil[]>} The studyUtils as an array.
	 */
	MagisterBinding.getStudyUtils = function (userId, options, callback) {
		check(userId, String);
		check(options, Match.Optional(Object));

		var options = _.defaults((options || {}), {

		});
		var magister = getMagisterObject(userId);
	};
})();
