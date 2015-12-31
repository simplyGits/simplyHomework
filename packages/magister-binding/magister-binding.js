/*
 * simplyHomework binding to Magister.
 * @author simply
 * @module magister-binding
 */
 /* global Magister, ExternalServicesConnector, Schools, gradeConverter, Grades,
  * Grade, StudyUtil, StudyUtils, GradePeriod, ExternalPerson, CalendarItem,
  * Assignment */

// One heck of a binding this is.

(function (Magister, Future, request, LRU) {
	'use strict';

	var ONLY_RECENT_LIMIT = 1000*60*60*24*6; // 6 days

	var cache = LRU({
		max: 50,
		// we cache magister objects infinitely currently since we also uesr
		// sessionIds infinitely, so we stay in style ;)
		maxAge: null,
	});

	/*
	 * A simplyHomework binding to Magister.
	 * @class MagisterBinding
	 * @static
	 */
	var MagisterBinding = {
		name: 'magister',
		friendlyName: 'Magister',
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
		 * @return {undefined|Boolean|Error} undefined if the data was stored, false if the login credentials are incorrect. Returns an error containg more info when an error occured.
		 */
		createData: function (schoolurl, username, password, userId) {
			check(schoolurl, String);
			check(username, String);
			check(password, String);
			check(userId, String);

			if (
				schoolurl.length === 0 ||
				username.length === 0 ||
				password.length === 0
			) {
				return false;
			}

			MagisterBinding.storedInfo(userId, {
				credentials: {
					schoolurl: schoolurl,
					username: username,
					password: password,
				},
			});

			// Remove the cache entry (if there's one) for the current user to
			// make sure we relogin.
			cache.del(userId);

			try {
				getMagisterObject(userId);
			} catch (e) {
				// Remove the stored info.
				cache.del(userId);
				MagisterBinding.storedInfo(userId, null);

				if (_.contains([
					'Ongeldig account of verkeerde combinatie van gebruikersnaam en wachtwoord. Probeer het nog eens of neem contact op met de applicatiebeheerder van de school.',
					'Je gebruikersnaam en/of wachtwoord is niet correct.',
				], e.message)) {
					return false;
				} else {
					return e;
				}
			}
		},
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
			cache.del(userId);
			throw new Error('No credentials found.');
		} else {
			var m = cache.get(userId);
			if (m !== undefined) {
				return m;
			}

			// REVIEW:
			// Currently not invalidating sessionIds, since it's unknown when
			// they retire at Magister's servers. Maybe they're even infinite.
			var useSessionId = !_.isEmpty(data.lastLogin);

			var magister = new Magister.Magister({
				school: {
					url: data.credentials.schoolurl,
				},
				username: data.credentials.username,
				password: data.credentials.password,
				keepLoggedIn: true,
				sessionId: useSessionId ? data.lastLogin.sessionId : undefined,
			});

			if (!useSessionId) { // Update login info
				MagisterBinding.storedInfo(userId, {
					lastLogin: {
						time: new Date(),
						sessionId: magister._sessionId,
					},
				});
			}

			magister.ready(function (err) {
				if (err) {
					fut.throw(new Error(err.message));
				} else {
					var school = Schools.findOne({
						'externalInfo.magister.url': magister.magisterSchool.url,
					});
					magister.magisterSchool.id = school && school.externalInfo.magister.id;
					fut.return(magister);
				}
			});

			m = fut.wait();
			cache.set(userId, m);
			return m;
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
	 * @return {Grade[]} The grades as a grade array.
	 */
	MagisterBinding.getGrades = function (userId, options) {
		check(userId, String);
		check(options, Match.Optional(Object));

		var fut = new Future();

		var magister = getMagisterObject(userId);
		var user = Meteor.users.findOne(userId);
		var lastUpdateTime = user.events.gradeUpdate;
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
					var stored = Grades.findOne({
						fetchedBy: MagisterBinding.name,
						externalId: magister.magisterSchool.id + '_' + g.id(),
						weight: g.counts() ? g.weight() : 0,
						grade: gradeConverter(g.grade()),
					});

					if (stored) {
						result[i] = stored;
					} else {
						var gradeFut = new Future();
						futs.push(gradeFut);

						g.fillGrade(function (e) {
							if (e) {
								gradeFut.throw(e);
							} else  {
								// REVIEW: Do we want a seperate weight field?
								var weight = g.counts() ? g.weight() : 0;
								var classInfo = _.find(user.classInfos, function (i) {
									return i.externalInfo.id === g.class().id;
								});
								var classId = classInfo && classInfo.id;

								var grade = new Grade(
									gradeConverter(g.grade()),
									weight,
									classId,
									userId
								);

								// REVIEW: Better way to check percentages than
								// this?
								if (g.type().header() === '%') {
									grade.gradeType = 'percentage';
								}
								grade.fetchedBy = MagisterBinding.name;
								grade.externalId = magister.magisterSchool.id + '_' + g.id();
								grade.description = g.description().trim();
								grade.passed = g.passed() || grade.passed;
								grade.dateFilledIn = g.dateFilledIn();
								grade.dateTestMade = g.testDate();
								grade.isEnd = g.type().isEnd();
								grade.period = new GradePeriod(
									g.gradePeriod().id,
									g.gradePeriod().name
								);

								result[i] = grade;
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
										parentId: sg.id(),
									},
								});

								if (stored) {
									result.push(stored);
								} else {
									var classId = _.filter(user.classInfos, function (i) {
										return i.externalInfo.abbreviation === sg.classCodes()[0];
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
										parentId: sg.id(),
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
		var magister = getMagisterObject(userId);
		magister.getPersons(query, type, function (e, r) {
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

					person.externalId = magister.magisterSchool.id + '_' + p.id();
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

		var magister = getMagisterObject(userId);
		magister.appointments(from, to, false, function (e, r) {
			if (e) {
				fut.throw(e);
			} else {
				fut.return(r.map(function (a) {
					var classInfo = _.find(user.classInfos, function (i) {
						return i.externalInfo.name === a.classes()[0];
					});
					var classId = classInfo && classInfo.id;

					var calendarItem = new CalendarItem(
						userId,
						a.description(),
						a.begin(),
						a.end(),
						classId
					);

					calendarItem.usersDone = a.isDone() ? [ userId ] : [];
					calendarItem.externalId = magister.magisterSchool.id + '_' + a.id();
					calendarItem.fetchedBy = MagisterBinding.name;
					if (!_.isEmpty(a.content())) {
						calendarItem.content = {
							type: a.infoTypeString(),
							description: a.content(),
						};
					}
					calendarItem.scrapped = a.scrapped();
					calendarItem.fullDay = a.fullDay();
					calendarItem.schoolHour = a.beginBySchoolHour();
					calendarItem.location = a.location();

					var absenceInfo = a.absenceInfo();
					if (absenceInfo != null) {
						calendarItem.absenceInfo = {
							externalId: magister.magisterSchool.id + '_' + absenceInfo.id(),
							type: absenceInfo.typeString(),
							permitted: absenceInfo.permitted(),
							description: absenceInfo.description(),
						};
					}

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
						})(c.teacher()),
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

		Magister.MagisterSchool.getSchools(query, function (e, r) {
			if (e) {
				fut.throw(e);
			} else {
				fut.return(r);
			}
		});

		return fut.wait();
	};

	MagisterBinding.getProfileData = function (userId) {
		check(userId, String);

		var magister = getMagisterObject(userId);
		var pictureUrl = magister.profileInfo().profilePicture(350, 350, true);

		var pictureFut = new Future();
		var courseInfoFut = new Future();

		request.get({
			url: pictureUrl,
			encoding: null,
			headers: {
				cookie: magister.http._cookie,
			},
		}, function (error, response, body) {
			pictureFut.return(
				body ?
					'data:image/jpg;base64,' + body.toString('base64') :
					''
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
		var pf = magister.profileInfo();
		return {
			nameInfo: {
				firstName: pf.firstName(),
				lastName: (pf.namePrefix() || '') + ' ' + pf.lastName(),
			},
			birthDate: pf.birthDate(),
			picture: pictureFut.wait(),
			courseInfo: {
				year: courseInfo.type.year,
				schoolVariant: courseInfo.type.schoolVariant != null ? courseInfo.type.schoolVariant.toLowerCase() : undefined,
				profile: courseInfo.profile,
			},
			mainGroup: courseInfo.group,
		};
	};

	// TODO: add docs here.
	MagisterBinding.getAssignments = function (userId) {
		check (userId, String);

		var fut = new Future();
		var user = Meteor.users.findOne(userId);

		//# @method assignments
		//# @async
		//# @param [amount=50] {Number} The amount of Assignments to fetch from the server.
		//# @param [skip=0] {Number} The amount of Assignments to skip.
		//# @param [fillPersons=false] {Boolean} Whether or not to download the full user objects from the server.
		//# @param [fillClass=true] {Boolean} Whether or not to download the full class objects from the server. If this is false Assignment.class() will return null.
		//# @param callback {Function} A standard callback.
		//# 	@param [callback.error] {Object} The error, if it exists.
		//# 	@param [callback.result] {Assignment[]} An array containing Assignments.
		var magister = getMagisterObject(userId);
		magister.assignments(function (e, r) {
			if (e) {
				fut.throw(e);
			} else {
				fut.return(r.map(function (a) {
					var classInfo = _.find(user.classInfos, function (i) {
						return i.externalInfo.id === a.class().id();
					});

					var assignment = new Assignment(
						a.name(),
						classInfo ? classInfo.id : undefined,
						a.deadline()
					);

					assignment.description = a.description();
					assignment.externalId = magister.magisterSchool.id + '_' + a.id();
					assignment.fetchedBy = MagisterBinding.name;

					return assignment;
				}));
			}
		});

		return fut.wait();
	};

	ExternalServicesConnector.pushExternalService(MagisterBinding);
})(Magister, Npm.require('fibers/future'), Npm.require('request'), Npm.require('lru-cache'));
