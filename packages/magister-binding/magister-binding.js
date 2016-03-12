/**
 * simplyHomework binding to Magister.
 * @author simply
 * @module magister-binding
 */
 /* global AbsenceInfo, Magister, ExternalServicesConnector, Schools, Grades,
  Grade, StudyUtil, GradePeriod, ExternalPerson, CalendarItem, Assignment,
  ExternalFile, getClassInfos, getUserField, LRU, Message, ms */

// One heck of a binding this is.

(function (Magister, Future, request, marked) {
	'use strict';

	const ONLY_RECENT_LIMIT = ms.days(6);

	const cache = LRU({
		max: 50,
		// we cache magister objects infinitely currently since we also uesr
		// sessionIds infinitely, so we stay in style ;)
		maxAge: null,
	});

	const renderer = new marked.Renderer();
	renderer.code = (str) => str;
	renderer.heading = (str) => str;
	marked.setOptions({
		renderer,
		gfm: true,
		tables: false,
		breaks: true,
		pedantic: false,
		sanitize: false,
		smartLists: true,
		smartypants: true,
	});

	/**
	 * A simplyHomework binding to Magister.
	 * @class MagisterBinding
	 * @static
	 */
	const MagisterBinding = {
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
	 * @param {Boolean} [forceNew=false] Get a new sessionId, even when there is a previous one.
	 * @return {Magister} A Magister object for the given `userId`.
	 */
	function getMagisterObject (userId, forceNew = false) {
		check(userId, String);
		check(forceNew, Boolean);

		const fut = new Future();
		const data = MagisterBinding.storedInfo(userId);
		if (_.isEmpty(data)) {
			cache.del(userId);
			throw new Error('No credentials found.');
		} else {
			let m = cache.get(userId);
			if (m !== undefined) {
				return m;
			}

			const useSessionId = !forceNew && !_.isEmpty(data.lastLogin);

			const magister = new Magister.Magister({
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
					externalUserId: magister.profileInfo().id(),
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
					const school = Schools.findOne({
						'externalInfo.magister.url': magister.magisterSchool.url,
					});
					magister.magisterSchool.id = school && school.externalInfo.magister.id;
					fut.return(magister);
				}
			});

			try {
				m = fut.wait();
			} catch (e) {
				if (useSessionId) { // retry with new sessionId when currently using an older one.
					return getMagisterObject(userId, true);
				}
				throw e;
			}
			cache.set(userId, m);
			return m;
		}
	}

	function prefixId (magister, id) {
		return magister.magisterSchool.id + '_' + id;
	}

	/**
	 * Gets the current course for the given Magister object.
	 * @method getCurrentCourse
	 * @private
	 * @param {Magister} magister The Magister object to get the course from.
	 * @return {Course} The current course.
	 */
	function getCurrentCourse (magister) {
		const fut = new Future();
		magister.currentCourse(fut.resolver());
		return fut.wait();
	}

	/**
	 * Get the grades for the given userId from Magister.
	 * @method getGrades
	 * @param {String} userId The ID of the user to get the grades from.
	 * @param {Object} [options] Optional map of options.
	 * @return {Grade[]} The grades as a grade array.
	 */
	MagisterBinding.getGrades = function (userId, options) {
		check(userId, String);
		check(options, Match.Optional(Object));

		const fut = new Future();

		const magister = getMagisterObject(userId);
		const user = Meteor.users.findOne(userId);
		const lastUpdateTime = user.events.gradeUpdate;
		const onlyRecent = options.onlyRecent ||
			lastUpdateTime && (_.now() - lastUpdateTime.getTime() <= ONLY_RECENT_LIMIT);

		const course = getCurrentCourse(magister);
		if (course == null) {
			throw new Meteor.Error('no-course');
		}

		course.grades(false, false, onlyRecent, function (e, r) {
			if (e) {
				fut.throw(e);
			} else {
				const result = new Array(r.length);
				const futs = [];

				r
				.filter(function (g) {
					return [14, 4].indexOf(g.type().type()) === -1;
				})
				.forEach(function (g, i) {
					// HACK: WET (unDRY, ;)) code.
					const stored = Grades.findOne({
						fetchedBy: MagisterBinding.name,
						externalId: prefixId(magister, g.id()),
						weight: g.counts() ? g.weight() : 0,
						gradeStr: g.grade(),
					});

					if (stored) {
						result[i] = stored;
					} else {
						const gradeFut = new Future();
						futs.push(gradeFut);

						g.fillGrade(function (e) {
							if (e) {
								gradeFut.throw(e);
							} else  {
								const classInfo = _.find(user.classInfos, function (i) {
									const abbr = i.externalInfo.abbreviation == g.class().abbreviation;
									const id = i.externalInfo.id === g.class().id;
									return abbr || id;
								});
								const classId = classInfo && classInfo.id;

								const grade = new Grade(
									g.grade(),
									g.counts() ? g.weight() : 0,
									classId,
									userId
								);

								// REVIEW: Better way to check percentages than
								// this?
								if (g.type().header() === '%') {
									grade.gradeType = 'percentage';
								}
								grade.fetchedBy = MagisterBinding.name;
								grade.externalId = prefixId(magister, g.id());
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

				for(let i = 0; i < futs.length; i++) futs[i].wait();
				fut.return(result);
			}
		});

		return fut.wait();
	};

	/**
	 * Converts the given `file` to a ExternalFile.
	 * @method convertMagisterFile
	 * @param prefix {String}
	 * @param file {File} The Magister file to convert.
	 * @param [usePersonPath=false] {Boolean}
	 * @return {ExternalFile} The given `file` converted to a ExternalFile.
	 */
	const convertMagisterFile = function (prefix, file, usePersonPath = false) {
		check(prefix, String);
		check(file, Magister.File);
		check(usePersonPath, Boolean);

		const res = new ExternalFile(file.name());

		res.name = file.name();
		res.mime = file.mime();
		res.creationDate = file.creationDate();
		res.size = file.size();

		const uri = file.uri();
		if (uri) {
			res.downloadInfo = {
				redirect: uri,
			};
		} else if (usePersonPath) {
			res.downloadInfo = {
				personPath: prefix + file.id(),
			};
		} else {
			res.downloadInfo = {
				pupilPath: prefix + file.id(),
			};
		}
		res.fetchedBy = MagisterBinding.name;
		res.externalId = prefixId(file._magisterObj, file.id());

		return res;
	};

	MagisterBinding.getFile = function (userId, info) {
		check(userId, String);
		check(info, Object);

		const magister = getMagisterObject(userId);
		let url;
		if (info.pupilPath) {
			url = `${magister._pupilUrl}/${info.pupilPath}`;
		} else if (info.personPath) {
			url = `${magister._personUrl}/${info.personPath}`;
		}

		return request({
			method: 'get',
			url: url,
			headers: {
				cookie: magister.http._cookie,
			},
		});
	};

	/**
	 * Get the studyUtil for the given userId from Magister.
	 * @method getStudyUtils
	 * @param {String} userId The ID of the user to get the studyUtil from.
	 * @return {StudyUtil[]} The studyUtils as an array.
	 */
	MagisterBinding.getStudyUtils = function (userId, options) {
		check(userId, String);
		check(options, Match.Optional(Object));

		const fut = new Future();

		const magister = getMagisterObject(userId);
		const classInfos = getClassInfos(userId);

		magister.studyGuides(false, function (e, r) {
			if (e) {
				fut.throw(e);
			} else {
				const studyUtils = [];
				const files = [];
				const futs = [];

				r.forEach(function (sg) {
					const studyGuideFut = new Future();
					futs.push(studyGuideFut);

					sg.parts(function (e, r) {
						if (e) {
							studyGuideFut.throw(e);
						} else {
							r.forEach(function (sgp) {
								const path = `/studiewijzers/${sg.id()}/onderdelen/${sgp.id()}/bijlagen/`;
								const classInfo = _.find(classInfos, (i) => {
									return _.contains(sg.classCodes(), i.externalInfo.abbreviation);
								});
								const classId = classInfo && classInfo.id;

								const studyUtil = new StudyUtil(
									sgp.name(),
									sgp.description(),
									classId,
									userId
								);

								studyUtil.visibleFrom = sgp.from();
								studyUtil.visibleTo = sgp.to();
								studyUtil.fetchedBy = MagisterBinding.name;
								studyUtil.externalInfo = {
									partId: sgp.id(),
									parentId: sg.id(),
								};
								sgp.files().forEach((file) => {
									const externalFile = convertMagisterFile(path, file);
									studyUtil.fileIds.push(externalFile._id);
									files.push(externalFile);
								})

								studyUtils.push(studyUtil);
							});
							studyGuideFut.return();
						}
					});
				});

				for(let i = 0; i < futs.length; i++) futs[i].wait();
				fut.return({
					studyUtils,
					files,
				});
			}
		});

		return fut.wait();
	};

	function convertMagisterPerson (person, user) {
		const magister = getMagisterObject(user._id);
		const res = new ExternalPerson(
			person.firstName(),
			person.lastName()
		);

		res.type = person.type();
		res.fullName = person.fullName();
		res.namePrefix = person.namePrefix();
		res.teacherCode = person.teacherCode();
		res.group = person.group();

		res.externalId = prefixId(magister, person.id());
		res.fetchedBy = MagisterBinding.name;

		if (person.id() === magister.profileInfo().id()) {
			// performance shortcut
			res.userId = user._id;
		} else {
			const u = Meteor.users.findOne({
				'profile.schoolId': user.profile.schoolId,
				'externalServices.magister.externalUserId': person.id(),
			});
			if (u !== undefined) {
				res.userId = u._id;
			}
		}

		return res;
	}

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

		const fut = new Future();
		const user = Meteor.users.findOne(userId);

		getMagisterObject(userId).getPersons(query, type, function (e, r) {
			if (e) {
				fut.error(e);
			} else {
				fut.return(r.map((p) => convertMagisterPerson(p, user)));
			}
		});
		return fut.wait();
	};

	MagisterBinding.getCalendarItems = function (userId, from, to) {
		check(userId, String);
		check(from, Date);
		check(to, Date);

		const fut = new Future();

		const user = Meteor.users.findOne(userId);

		const magister = getMagisterObject(userId);
		const path = '/afspraken/bijlagen/';

		magister.appointments(from, to, false, function (e, r) {
			if (e) {
				fut.throw(e);
			} else {
				const futs = [];

				const calendarItems = [];
				const absenceInfos = [];
				const files = [];

				for (let i = 0; i < r.length; i++) {
					const a = r[i];

					const fut = new Future();
					futs.push(fut);

					const classInfo = _.find(user.classInfos, function (i) {
						const name = i.externalInfo.name;
						return name != null && name === a.classes()[0];
					});
					const classId = classInfo && classInfo.id;

					const calendarItem = new CalendarItem(
						userId,
						a.description(),
						a.begin(),
						a.end(),
						classId || undefined
					);

					calendarItem.usersDone = a.isDone() ? [ userId ] : [];
					calendarItem.externalId = prefixId(magister, a.id());
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
					calendarItem.type = (function (a) {
						switch (a.type()) {
						case 1: return 'personal';
						case 3: return 'schoolwide';
						case 7: return 'kwt';
						case 13: return 'lesson';
						}
					})(a);

					const teacher = a.teachers()[0];
					if (teacher != null) {
						calendarItem.teacher = {
							name: teacher.fullName(),
							id: teacher.id(),
						};
					}

					const info = a.absenceInfo();
					if (info != null) {
						const absenceInfo = new AbsenceInfo(
							userId,
							calendarItem._id,
							info.typeString(),
							info.permitted()
						);
						absenceInfo.description = info.description();
						absenceInfo.fetchedBy = MagisterBinding.name;
						absenceInfo.externalId = prefixId(magister, info.id());

						absenceInfos.push(absenceInfo);
					}

					a.attachments(function (e, r) {
						if (e == null) {
							r.forEach((file) => {
								const externalFile = convertMagisterFile(path, file, true);
								calendarItem.fileIds.push(externalFile._id);
								files.push(externalFile);
							});
						}
						fut.return();
					});

					calendarItems.push(calendarItem);
				}

				for(let i = 0; i < futs.length; i++) futs[i].wait();
				fut.return({
					calendarItems,
					absenceInfos,
					files,
				});
			}
		});

		return fut.wait();
	};

	MagisterBinding.getPersonClasses = function (userId) {
		check(userId, String);

		const fut = new Future();
		const magister = getMagisterObject(userId);

		const course = getCurrentCourse(magister);
		if (course == null) {
			throw new Meteor.Error('no-course');
		}

		course.classes(function (e, r) {
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
							const person = new ExternalPerson();
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

		const fut = new Future();

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

		const magister = getMagisterObject(userId);
		const pictureUrl = magister.profileInfo().profilePicture(350, 350, true);

		const pictureFut = new Future();
		const courseInfoFut = new Future();

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
			let result;
			if (e != null) {
				result = { type: {} };
			} else {
				result = r;
			}
			courseInfoFut.return(result);
		});

		const courseInfo = courseInfoFut.wait();
		const pf = magister.profileInfo();
		return {
			nameInfo: {
				firstName: pf.firstName(),
				lastName: (pf.namePrefix() || '') + ' ' + pf.lastName(),
			},
			birthDate: pf.birthDate(),
			picture: pictureFut.wait(),
			courseInfo: {
				year: courseInfo.type.year,
				schoolVariant: courseInfo.type.schoolVariant != null ? courseInfo.type.schoolVariant.toLowerCase() : '',
				profile: courseInfo.profile,
			},
			mainGroup: courseInfo.group,
		};
	};

	// TODO: add docs here.
	MagisterBinding.getAssignments = function (userId) {
		check (userId, String);

		const fut = new Future();
		const user = Meteor.users.findOne(userId);

		//# @method assignments
		//# @async
		//# @param [amount=50] {Number} The amount of Assignments to fetch from the server.
		//# @param [skip=0] {Number} The amount of Assignments to skip.
		//# @param [fillPersons=false] {Boolean} Whether or not to download the full user objects from the server.
		//# @param [fillClass=true] {Boolean} Whether or not to download the full class objects from the server. If this is false Assignment.class() will return null.
		//# @param callback {Function} A standard callback.
		//# 	@param [callback.error] {Object} The error, if it exists.
		//# 	@param [callback.result] {Assignment[]} An array containing Assignments.
		const magister = getMagisterObject(userId);
		magister.assignments(function (e, r) {
			if (e) {
				fut.throw(e);
			} else {
				fut.return(r.map(function (a) {
					const classInfo = _.find(user.classInfos, function (i) {
						return i.externalInfo.id === a.class().id();
					});

					const assignment = new Assignment(
						a.name(),
						classInfo ? classInfo.id : undefined,
						a.deadline()
					);

					assignment.description = a.description();
					assignment.externalId = prefixId(magister, a.id());
					assignment.fetchedBy = MagisterBinding.name;

					return assignment;
				}));
			}
		});

		return fut.wait();
	};

	MagisterBinding.getMessages = function (folderName, skip, limit, userId) {
		check(folderName, String);
		check(skip, Number);
		check(limit, Number);
		check(userId, String);

		const fut = new Future();
		const user = Meteor.users.findOne(userId);
		const magister = getMagisterObject(userId);

		let folder;
		if (folderName === 'inbox') {
			folder = magister.inbox();
		} else if (folderName === 'alerts') {
			folder = magister.alerts();
		} else if (folderName === 'outbox') {
			folder = magister.sentItems();
		} else {
			return []; // folder not supported.
		}

		folder.messages({
			limit: limit,
			skip: skip,
		}, function (e, r) {
			if (e) {
				fut.throw(e);
			} else {
				const messages = [];
				const files = [];

				r.forEach(function (m) {
					const path = '/berichten/bijlagen/';

					const message = new Message(
						m.subject(),
						m._body,
						folderName,
						m.sendDate(),
						convertMagisterPerson(m.sender(), user)
					);
					message.recipients = m.recipients().map((p) => convertMagisterPerson(p, user));
					message.fetchedBy = MagisterBinding.name;
					message.externalId = prefixId(magister, m.id());
					message.readBy = m.isRead() ? [ userId ] : [];

					m.attachments().forEach((file) => {
						const externalFile = convertMagisterFile(path, file, true);
						message.attachmentIds.push(externalFile._id);
						files.push(externalFile);
					});

					messages.push(message);
				});

				fut.return({
					messages,
					files,
				});
			}
		});

		return fut.wait();
	};

	MagisterBinding.sendMessage = function (subject, body, recipients, userId) {
		check(subject, String);
		check(body, String);
		check(recipients, [String]);
		check(userId, String);

		body = marked(body);

		const fut = new Future();
		getMagisterObject(userId).composeAndSendMessage(subject, body, recipients, function (e) {
			if (e) {
				fut.throw(e);
			} else {
				fut.return();
			}
		});

		return fut.wait();
	};

	/**
	 * @method replyMessage
	 * @param {String} id
	 * @param {Boolean} all
	 * @param {String} body
	 * @param {String} userId
	 */
	MagisterBinding.replyMessage = function (id, all, body, userId) {
		check(id, String);
		check(all, Boolean);
		check(body, String);
		check(userId, String);

		body = marked(body);

		const fut = new Future();
		const magister = getMagisterObject(userId);
		request({
			method: 'get',
			url: `${magister._personUrl}/berichten/${id}`,
			headers: {
				cookie: magister.http._cookie,
			},
		}, function (error, response, content) {
			if (response && response.statusCode >= 400) {
				fut.throw(content);
			} else {
				const parsed = JSON.parse(content);
				let message = Magister.Message._convertRaw(magister, parsed);

				if (all) {
					message = message.createReplyToAllMessage(body);
				} else {
					message = message.createReplyMessage(body);
				}
				message.send(fut.resolver());
			}
		});

		return fut.wait();
	}

	ExternalServicesConnector.pushExternalService(MagisterBinding);
})(Magister, Npm.require('fibers/future'), Npm.require('request'), Npm.require('marked'));
