/*
 * simplyHomework binding to Magister.
 * @author simply
 * @module magister-binding
 */

(function (m, Future, request) {
	"use strict";

	var SESSIONID_INVALIDATE_TIME = 1000*60*60*24; // 24 hours
	var ONLY_RECENT_LIMIT = 1000*60*60*24*6; // 6 days

	/*
	 * A simplyHomework binding to Magister.
	 * @class MagisterBinding
	 * @static
	 */
	MagisterBinding = {
		name: "magister",
		friendlyName: "Magister",
		loginNeeded: true,
		/**
		 * Creates data for the user with given `userId` with the given
		 * parameters.
		 *
		 * @method createData
		 * @param {String} schoolurl
		 * @param {String} username
		 * @param {String} password
		 * @param {String} userId The ID of the user to save the info to.
		 * @return {Object|Boolean|undefined} True if the data was stored, false if the login credentials are incorrect. `undefined` if an other error occured.
		 */
		createData: function (schoolurl, username, password, userId) {
			check(schoolurl, String);
			check(username, String);
			check(password, String);
			check(userId, String);

			MagisterBinding.storedInfo(userId, {
				credentials: {
					schoolurl: schoolurl,
					username: username,
					password: password
				}
			});

			try {
				getMagisterObject(userId);
			} catch (e) {
				if (e.statusCode === 403) {
					// login credentials wrong, remove the stored info.
					MagisterBinding.storedInfo(userId, null);
					return false;
				} else {
					return undefined;
				}
			}

			return true;
		}
	};

	/**
	 * Gets a magister object for the given `userId`.
	 * @method getMagisterObject
	 * @private
	 * @param {String} userId The ID of the user to get a Magister object for.
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
				keepLoggedIn: true,
				sessionId: useSessionId ? data.lastLogin.sessionId : undefined
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
	 * @param {Magister} magister The Magister object to get the course from.
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
	 * @param {String} userId The ID of the user to get the grades from.
	 * @param {Object} [options] Optional map of options.
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

		var course = getCurrentCourse(magister);
		course.grades(false, false, onlyRecent, function (e, r) {
			if (e) {
				fut.throw(e);
			} else {
				var result = new Array(r.length);
				var futs = [];

				r
				.filter(function (g) {
					return [14].indexOf(g.type().type()) === -1;
				})
				.forEach(function (g, i) {
					// HACK: WET (unDRY, ;)) code.
					var stored = StoredGrades.findOne({
						fetchedBy: MagisterBinding.name,
						externalId: g.id(),
						weight: g.counts() ? g.weight() : 0,
						grade: gradeConverter(g.grade())
					});

					if (stored) {
						result[i] = stored;
						console.log('already stored', g, stored);
					} else {
						var gradeFut = new Future();
						futs.push(gradeFut);

						g.fillGrade(function (e, r) {
							if (e) {
								console.log('err', e);
								gradeFut.throw(e);
							} else  {
								var weight = g.counts() ? g.weight() : 0;
								var classId = _.find(user.classInfos, function (i) {
									return i.externalInfo.id === g.class().id;
								}).id;

								var storedGrade = new StoredGrade(
									gradeConverter(g.grade()),
									weight,
									classId,
									userId
								);

								storedGrade.fetchedBy = MagisterBinding.name;
								storedGrade.externalId = g.id();
								storedGrade.description = g.description().trim();
								storedGrade.passed = g.passed() || storedGrade.passed;
								storedGrade.dateFilledIn = g.dateFilledIn();
								storedGrade.dateTestMade = g.testDate();
								storedGrade.isEnd = g.type().type() === 2;
								storedGrade.period = new GradePeriod(
									g.gradePeriod().id,
									g.gradePeriod().name
								);

								result[i] = storedGrade;
								console.log('just stored', g, storedGrade);
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
	 * @param {String} userId The ID of the user to get the studyUtil from.
	 * @return {StudyUtil[]} The studyUtils as an array.
	 */
	MagisterBinding.getStudyUtils = function (userId, options) {
		check(userId, String);
		check(options, Match.Optional(Object));

		var fut = new Future();

		var magister = getMagisterObject(userId);
		var user = Meteor.users.findOne(userId);

		magister.studyGuides(false, function (e, r) {
			if (e) {
				fut.throw(e);
			} else {
				var result = [];
				var futs = [];

				r.forEach(function (sg) {
					var studyGuideFut = new Future();
					futs.push(studyGuideFut);

					sg.parts(function (e, r) {
						if (e) {
							studyGuideFut.throw(e);
						} else {
							r.forEach(function (sgp) {
								var stored = StudyUtils.findOne({
									fetchedBy: MagisterBinding.name,
									externalInfo: {
										partId: sgp.id(),
										parentId: sg.id()
									}
								});

								if (stored) {
									result.push(stored);
								} else {
									var classId = _.filter(user.classInfos, function (i) {
										return i.externalInfo.abbreviation === g.classCodes()[0];
									}).id;

									var studyUtil = new StudyUtil(
										sgp.name(),
										sgp.description(),
										classId,
										userId
									);

									studyUtil.fetchedBy = MagisterBinding.name;
									studyUtil.visibleFrom = sgp.from();
									studyUtil.visibleTo = sgp.to();
									studyUtil.externalInfo = {
										partId: sgp.id(),
										parentId: sg.id()
									};
									// TODO == Find a good universal file class profile and make a magister
									// file converter for it.
									//studyUtil.files = xxx.fromMagister files

									result.push(studyUtil);
								}
							});
							studyGuideFut.return();
						}
					});
				});

				for(var i = 0; i < futs.length; i++) futs[i].wait();
				fut.return(result);
			}
		});

		return fut.wait();
	};

	/**
	 * Gets persons for the user with the given `userId` confirming to the
	 * given `query` and `type`, if given.
	 *
	 * @method getPersons
	 * @param {String} userId The ID of the user to fetch the persons for.
	 * @param {String} query
	 * @param {String} [type]
	 * @return {ExternalPerson[]}
	 */
	MagisterBinding.getPersons = function (userId, query, type) {
		check(userId, String);
		check(query, String);
		check(type, Match.Optional(String));

		var fut = new Future();
		getMagisterObject(userId).getPersons(query, type, function (e, r) {
			if (e) {
				fut.error(e);
			} else {
				fut.return(r.map(function (p) {
					var person = new ExternalPerson(
						p.firstName(),
						p.lastName()
					);

					person.type = p.type();
					person.fullName = p.fullName();
					person.namePrefix = p.namePrefix();
					person.teacherCode = p.teacherCode();
					person.group = p.group();

					person.externalId = p.id();
					person.fetchedBy = MagisterBinding.name;

					return person;
				}));
			}
		});
		return fut.wait();
	};

	MagisterBinding.getCalendarItems = function (userId, from, to) {
		check(userId, String);
		check(from, Date);
		check(to, Date);

		var fut = new Future();
		var user = Meteor.users.findOne(userId);

		getMagisterObject(userId).appointments(from, to, false, function (e, r) {
			if (e) {
				fut.throw(e);
			} else {
				fut.return(r.map(function (a) {
					var classId = _.filter(user.classInfos, function (i) {
						return i.externalInfo.abbreviation === a.classes()[0];
					}).id;

					var calendarItem = new CalendarItem(
						userId,
						a.description(),
						a.begin(),
						a.end(),
						classId
					);

					calendarItem.isDone = a.isDone();
					calendarItem.externalId = a.id();
					calendarItem.fetchedBy = MagisterBinding.name;
					if (!_.isEmpty(a.content())) {
						calendarItem.content = {
							type: a.infoTypeString(),
							description: a.content()
						};
					}
					calendarItem.scrapped = a.scrapped();
					calendarItem.fullDay = a.fullDay();
					calendarItem.schoolHour = a.beginBySchoolHour();
					calendarItem.location = a.location();

					return calendarItem;
				}));
			}
		});

		return fut.wait();
	};

	MagisterBinding.getClasses = function (userId) {
		check(userId, String);

		var fut = new Future();
		var magister = getMagisterObject(userId);

		getCurrentCourse(magister).classes(function (e, r) {
			if (e) {
				fut.throw(e);
			} else {
				fut.return(r.map(function (c) {
					return {
						abbreviation: c.abbreviation(),
						begin: c.beginDate(),
						end: c.endDate(),
						exemption: c.classExemption(),
						name: c.description(),
						id: c.id(),
						teacher: (function (t) {
							var person = new ExternalPerson();
							person.teacherCode = t.teacherCode();
							person.fetchedBy = MagisterBinding.name;
							return person;
						})(c.teacher())
					};
				}));
			}
		});

		return fut.wait();
	};

	/**
	 * Gets schools matching the given `query`
	 * @method getSchools
	 * @param {String} query
	 * @return {School[]}
	 */
	MagisterBinding.getSchools = function (query) {
		check(query, String);

		var fut = new Future();

		m.MagisterSchool.getSchools(query, function (e, r) {
			if (e) {
				fut.throw(e);
			} else {
				fut.return(r.map(function (s) {
					var school = new School(s.name, s.url);
					school.fetchedBy = MagisterBinding.name;
					school.externalId = s.id;
					return school;
				}));
			}
		});

		return fut.wait();
	};

	MagisterBinding.getProfileData = function (userId) {
		check(userId, String);

		var magister = getMagisterObject(userId);
		var pictureUrl = magister.profileInfo().profilePicture(200, 200, true);

		var pictureFut = new Future();
		var courseInfoFut = new Future();

		request.get({
			url: pictureUrl,
			encoding: null,
			headers: {
				cookie: magister.http._cookie
			}
		}, function (error, response, body) {
			pictureFut.return(
				body ?
					"data:image/jpg;base64," + body.toString("base64") :
					""
			);
		});

		magister.getLimitedCurrentCourseInfo(function (e, r) {
			var result;
			if (e != null) {
				result = { type: {} };
			} else {
				result = r;
			}
			courseInfoFut.return(result);
		});

		var courseInfo = courseInfoFut.wait();
		return {
			nameInfo: {
				firstName: magister.profileInfo().firstName(),
				lastName: magister.profileInfo().lastName()
			},
			birthDate: magister.profileInfo().birthDate(),
			picture: pictureFut.wait(),
			courseInfo: {
				year: courseInfo.type.year,
				schoolVariant: courseInfo.type.schoolVariant.toLowerCase(),
				profile: courseInfo.profile
			},
			externalSchoolId: magister.magisterSchool.id
		};
	};
})(Magister, Npm.require("fibers/future"), Meteor.npmRequire("request"));
