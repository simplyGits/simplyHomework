var m = Magister;
var Future = Npm.require("fibers/future");
var SESSIONID_INVALIDATE_TIME = 1000*60*60*24; // 24h

/*
 * A simplyHomework binding to Magister.
 * @class MagisterBinding
 * @static
 */
MagisterBinding = {
	dbName: "magister",
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
		var useSessionId = data.lastLogin &&
			_.now() - data.lastLogin.time.getTime() >= SESSIONID_INVALIDATE_TIME;

		var magister = new m.Magister({
			school: {
				url: data.credentials.schoolurl
			},
			username: data.credentials.username,
			password: data.credentials.password,
			// We invalidate the sessionId after a day of its creation.
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
				fut.return(this);
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

	magister.courses(function (e, r) {
		if (e){
			fut.throw(e);
		} else {
			fut.return(r[0]);
		}
	});

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

	var course = getCurrentCourse(magister);
	course.grades(false, true, options.onlyRecent, function (e, r) {
		if (e) {
			fut.throw(e);
		} else {
			var result = [];

			r.forEach(function (g) {
				var stored = StoredGrades.findOne({
					externalId: g.id()
				});

				if (stored) {
					result.push(stored);
				} else {
					var weight = g.counts() ? g.weight() : 0;
					var classId = _.filter(user.classInfos, function (i) {
						return i.magisterId === g.class().id();
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

					result.push(storedGrade);
				}
			});

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
