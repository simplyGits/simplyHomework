/* global AbsenceInfo, Schools, Grade, StudyUtil, GradePeriod,
          ExternalPerson, CalendarItem, Assignment, ExternalFile, getClassInfos,
          Message, ms, MagisterBinding, ServiceUpdate */

// One heck of a binding this is.

'use strict';
import Magister from 'magister.js';
import LRU from 'lru-cache';
import request from 'request';
import marked from 'marked';
import Mutex from 'meteor/mutex';
import Future from 'fibers/future';
import { AuthError } from 'meteor/simply:external-services-connector';

const ONLY_RECENT_LIMIT = ms.days(6);

const log = MagisterBinding.log;
// FIXME: this technically is a memory leak, since no keys are removed, but I
// don't think this is going to be a problem. And I don't even know what a
// better way to handle this would be.
const userMutexes = new Map();

const cache = LRU({
	max: 75,
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
 * Creates data for the user with given `userId` with the given
 * parameters.
 *
 * @method createData
 * @param {String} schoolurl
 * @param {String} username
 * @param {String} password
 * @param {String} userId The ID of the user to save the info to.
 * @throws {AuthError} Throws an AuthError when the given the given login credentials are incorrect.
 * @throws {Error} Throws an error containing more info when an unknown error occured.
 */
MagisterBinding.createData = function (schoolurl, username, password, userId) {
	check(schoolurl, String);
	check(username, String);
	check(password, String);
	check(userId, String);

	if (
		schoolurl.length === 0 ||
		username.length === 0 ||
		password.length === 0
	) {
		throw new AuthError('schoolurl, username, and password required');
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

	let magister;
	try {
		magister = getMagisterObject(userId);
	} catch (e) {
		// Remove the stored info.
		cache.del(userId);
		MagisterBinding.storedInfo(userId, null);
		throw e;
	}

	magister.profileInfo().settings(function (e, r) {
		if (e != null) return;

		// TODO: ask this nicely to the user in the setup (and when they enable
		// message alerts in the setup)

		r.redirectMagisterMessages(false);
		r.update(function (e) {
			// REVIEW: do we want to do something with `e`?
		});
	});
}

/**
 * @method getMutex
 * @param {String} userId
 * @return {Mutex} The mutex for the user
 */
function getMutex (userId) {
	let mutex = userMutexes.get(userId);

	if (mutex == null) {
		mutex = new Mutex();
		userMutexes.set(userId, mutex);
	}

	return mutex;
}

/**
 * Gets a magister object for the given `userId`.
 * @method getMagisterObject
 * @private
 * @param {String} userId The ID of the user to get a Magister object for.
 * @param {Boolean} [forceNew=false] Get a new sessionId and Magister object, even when there is a previous one.
 * @param {Mutex} [mutex] If provided, should be a locked mutex that will be
 * unlocked by this function.
 * @return {Magister} A Magister object for the given `userId`.
 */
function getMagisterObject (userId, forceNew = false, mutex) {
	check(userId, String);
	check(forceNew, Boolean);
	check(mutex, Match.Any);

	// if we aren't given a mutex object...
	if (mutex == null) {
		// we have to fetch one...
		mutex = getMutex(userId);
		// and we have to lock it (if a mutex is given we assume it's already
		// locked and we retrieved the lock).
		mutex.lock();
	}

	const data = MagisterBinding.storedInfo(userId);
	if (_.isEmpty(data)) {
		cache.del(userId);
		mutex.unlock();
		throw new Error('No credentials found.');
	} else {
		const m = cache.get(userId);
		if (m !== undefined && !forceNew) {
			mutex.unlock();
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

		try {
			Meteor.wrapAsync(magister.ready, magister)();
		} catch (err) {
			// HACK: logging in into Magister currently fails when the user
			// doesn't have enough privileges to get messagefolders.
			// So we just ignore the error and everything works (expect for
			// messages, of course).
			// This will be fixed in Magister.js v2.
			if (err.fouttype === 'OnvoldoendePrivileges') {
				magister._ready = true;
			} else {
				const e = (
					_.contains([
						'Ongeldig account of verkeerde combinatie van gebruikersnaam en wachtwoord. Probeer het nog eens of neem contact op met de applicatiebeheerder van de school.',
						'Je gebruikersnaam en/of wachtwoord is niet correct.',
					], err.message) ?
					new AuthError(err.message) :
					err
				);

				if (useSessionId) { // retry with new sessionId when currently using an older one.
					return getMagisterObject(userId, true, mutex);
				}

				if (e instanceof AuthError) { // when logging in fails we don't want to send the wrong password anymore to Magister.
					log(`logging in failed with AuthError for user with id '${userId}', removing storedInfo`);
					MagisterBinding.storedInfo(userId, null);
				}

				mutex.unlock();
				throw e;
			}
		}

		const school = Schools.findOne({
			'externalInfo.magister.url': magister.magisterSchool.url,
		});
		magister.magisterSchool.id = school && school.externalInfo.magister.id;

		if (!useSessionId) { // Update login info
			const getVersionInfo = Meteor.wrapAsync(
				magister.magisterSchool.versionInfo,
				magister.magisterSchool
			);

			MagisterBinding.storedInfo(userId, {
				externalUserId: magister.profileInfo().id(),
				lastLogin: {
					time: new Date(),
					sessionId: magister._sessionId,
					apiVersion: getVersionInfo().api,
				},
			});
		}

		mutex.unlock();
		cache.set(userId, magister);
		return magister;
	}
}

function prefixId (magister, ...args) {
	let res = magister.magisterSchool.id;
	for (const arg of args) {
		res += '_' + arg;
	}
	return res;
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

	const magister = getMagisterObject(userId);
	const user = Meteor.users.findOne(userId);
	// TODO: fix this onlyRecent stuff.
	//const lastUpdateTime = user.events.gradeUpdate;
	//const onlyRecent = options.onlyRecent ||
	//	lastUpdateTime && (_.now() - lastUpdateTime.getTime() <= ONLY_RECENT_LIMIT);

	const course = getCurrentCourse(magister);
	if (course == null) {
		return [];
	}

	const grades = Meteor.wrapAsync(course.grades, course)({
		fillPersons: false,
		fillGrade: true,
	});

	return _.chain(grades)
	.filter(g => ![14, 4].includes(g.type().type()))
	.groupBy(g => g.class().abbreviation)
	.pairs()
	.map(pair => {
		const grades = pair[1];
		const maxGrade = _.max(grades, g => g.period().number());
		return _.map(grades, g => {
			if (g !== maxGrade && g.type().isEnd()) {
				g.type()._type = 1;
			}
			return g;
		})
	})
	.flatten()
	.map(g => {
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
			g.period().id(),
			g.period().name()
		);

		return grade;
	})
	.value();
};

/**
 * Converts the given `file` to a ExternalFile.
 * @method convertMagisterFile
 * @param userId {String}
 * @param prefix {String}
 * @param file {File} The Magister file to convert.
 * @param [usePersonPath=false] {Boolean}
 * @return {ExternalFile} The given `file` converted to a ExternalFile.
 */
const convertMagisterFile = function (userId, prefix, file, usePersonPath = false) {
	check(userId, String);
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
			userId,
			personPath: prefix + file.id(),
		};
	} else {
		res.downloadInfo = {
			userId,
			pupilPath: prefix + file.id(),
		};
	}
	res.fetchedBy = MagisterBinding.name;
	res.externalId = prefixId(file._magisterObj, file.id());

	return res;
};

MagisterBinding.getFile = function (info) {
	check(info, Object);

	const magister = getMagisterObject(info.userId);
	const url = info.pupilPath ?
		`${magister._pupilUrl}/${info.pupilPath}` :
		`${magister._personUrl}/${info.personPath}`;

	return request({
		method: 'get',
		url: url,
		headers: {
			cookie: magister.http._cookie,
			'X-API-Client-ID': '12D8',
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

	const studyGuides = Meteor.wrapAsync(magister.studyGuides, magister)(false);

	const studyUtils = [];
	const files = [];
	const futs = [];

	studyGuides.forEach(function (sg) {
		const studyGuideFut = new Future();
		futs.push(studyGuideFut);

		sg.parts(function (e, r) {
			if (e) {
				studyGuideFut.throw(e);
				return;
			}

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
					const externalFile = convertMagisterFile(userId, path, file);
					studyUtil.fileIds.push(externalFile._id);
					files.push(externalFile);
				});

				studyUtils.push(studyUtil);
			});
			studyGuideFut.return();
		});
	});

	for (let i = 0; i < futs.length; i++) {
		try {
			futs[i].wait();
		} catch (e) {
			fut.throw(e);
			return;
		}
	}

	return {
		studyUtils,
		files,
	};
};

/**
 * @method convertMagisterPerson
 * @param {MagisterPerson} person The `MagisterPerson` to convert to an `ExternalPerson`
 * @param {User} user The Meteor user that fetched `person`, used to prefix the
 * person with the users's school id and for a performance shortcut.
 * @return {ExternalPerson}
 */
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
 * @param {String[]} [types]
 * @return {ExternalPerson[]}
 */
MagisterBinding.getPersons = function (userId, query, types) {
	check(userId, String);
	check(query, String);
	check(types, [String]);

	const user = Meteor.users.findOne(userId);
	const type = types.length === 1 ? types[0] : undefined;

	const fut = new Future();
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

	const user = Meteor.users.findOne(userId);

	const magister = getMagisterObject(userId);
	const path = '/afspraken/bijlagen/';

	const getAppointments = Meteor.wrapAsync(magister.appointments, magister);
	const appointments = getAppointments(from, to, false);

	const futs = [];

	const calendarItems = [];
	const absences = [];
	const files = [];

	for (const a of appointments) {
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
		calendarItem.externalInfo = {
			id: prefixId(magister, a.id()),
			editable: false,
		};
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
				id: teacher.id(),
				name: teacher.fullName(),
				code: teacher.teacherCode(),
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
			absenceInfo.externalInfo = {
				id: prefixId(magister, info.id()),
			};

			absences.push(absenceInfo);
		}

		a.attachments(function (e, r) {
			if (e == null) {
				r.forEach((file) => {
					const externalFile = convertMagisterFile(userId, path, file, true);
					calendarItem.fileIds.push(externalFile._id);
					files.push(externalFile);
				});
			}
			fut.return();
		});

		calendarItems.push(calendarItem);
	}

	for (let i = 0; i < futs.length; i++) futs[i].wait();

	return {
		calendarItems,
		absences,
		files,
	};
};

MagisterBinding.getPersonClasses = function (userId) {
	check(userId, String);

	const magister = getMagisterObject(userId);

	const course = getCurrentCourse(magister);
	if (course == null) {
		throw new Meteor.Error('no-course');
	}

	const classes = Meteor.wrapAsync(course.classes, course)();
	return classes.map(function (c) {
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
	});
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
			'X-API-Client-ID': '12D8',
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
			lastName: _([ pf.namePrefix(), pf.lastName() ]).compact().join(' '),
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
			return;
		}

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
	});

	return fut.wait();
};

MagisterBinding.getMessages = function (userId, folderName, skip, limit) {
	check(userId, String);
	check(folderName, String);
	check(skip, Number);
	check(limit, Number);

	const user = Meteor.users.findOne(userId);
	const magister = getMagisterObject(userId);

	const folder = ({
		'inbox': magister.inbox(),
		'outbox': magister.sentItems(),
	})[folderName];
	if (folder == null) { // folder not supported.
		return {
			messages: [],
			files: [],
		};
	}

	let res = Meteor.wrapAsync(folder.messages, folder)({
		limit,
		skip,
	});
	res = res || []; // HACK

	const messages = [];
	const files = [];

	res.forEach(function (m) {
		const path = '/berichten/bijlagen/';

		const message = new Message(
			m.subject(),
			m._body,
			folderName,
			m.sendDate(),
			convertMagisterPerson(m.sender(), user),
			userId
		);
		message.recipients = m.recipients().map((p) => convertMagisterPerson(p, user));
		message.fetchedBy = MagisterBinding.name;
		message.externalId = prefixId(magister, m.id());
		messages.isRead = m.isRead();
		message.hasPriority = m.isFlagged();

		const attachments = m.attachments() || []; // HACK
		attachments.forEach((file) => {
			const externalFile = convertMagisterFile(userId, path, file, true);
			message.attachmentIds.push(externalFile._id);
			files.push(externalFile);
		});

		messages.push(message);
	});

	return {
		messages,
		files,
	};
};

MagisterBinding.getUpdates = function (userId) {
	check(userId, String);

	const magister = getMagisterObject(userId);
	const folder = magister.alerts();

	if (folder == null) {
		return [];
	}

	let res = Meteor.wrapAsync(folder.messages, folder)({
		skip: 0,
		limit: 100, // we want get all the alerts
	});
	res = res || []; // HACK

	return res.map(function (m) {
		const update = new ServiceUpdate(
			m.subject(),
			m.body(),
			userId,
			MagisterBinding.name,
			prefixId(magister, m.id())
		);

		update.date = m.sendDate();

		return update;
	})
}

/**
 * Compiles the given body: render TeX equations and convert markdown to html
 * @method compileMessageBody
 * @param {String} body
 * @return {String}
 */
function compileMessageBody (body) {
	check(body, String);

	const base = 'https://latex.codecogs.com/png.latex?';
	const genimg = (url) => `<img src="${url}"></img>`;

	// inline
	body = body.replace(/\$\$ *(.+?) *\$\$/g, function (match, expr) {
		const url = base + encodeURIComponent(`\\inline ${expr}`);
		return genimg(url);
	});

	// multiline
	body = body.replace(/^[ \t]*\$\$[ \t]*$\n((\n|.)+?)\n^[ \t]*\$\$[ \t]*$/gm, function (match, expr) {
		const url = base + encodeURIComponent(`\\dpi{130} \\large ${expr}`);
		return `\n\n${genimg(url)}\n\n`;
	});

	body = marked(body);

	return body;
}

MagisterBinding.sendMessage = function (userId, subject, body, recipients) {
	check(userId, String);
	check(subject, String);
	check(body, String);
	check(recipients, [String]);

	body = compileMessageBody(body);

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
MagisterBinding.replyMessage = function (userId, id, all, body) {
	check(userId, String);
	check(id, String);
	check(all, Boolean);
	check(body, String);

	body = compileMessageBody(body);

	const fut = new Future();
	const magister = getMagisterObject(userId);
	request({
		method: 'get',
		url: `${magister._personUrl}/berichten/${id}`,
		headers: {
			cookie: magister.http._cookie,
			'X-API-Client-ID': '12D8',
		},
	}, function (error, response, content) {
		if (response && response.statusCode >= 400) {
			fut.throw(content);
			return;
		}

		const parsed = JSON.parse(content);
		let message = Magister.Message._convertRaw(magister, parsed);

		if (all) {
			message = message.createReplyToAllMessage(body);
		} else {
			message = message.createReplyMessage(body);
		}
		message.send(fut.resolver());
	});

	return fut.wait();
}

/**
 * @method validateLoginAttempt
 * @param {String} username
 * @param {String} digest
 * @return {String|null}
 */
MagisterBinding.validateLoginAttempt = function (username, digest) {
	const users = Meteor.users.find({
		'externalServices.magister.credentials.username': username,
	}, {
		fields: {
			_id: 1,
			'externalServices.magister.credentials': 1,
		},
	}).fetch();

	for (const user of users) {
		const hash = Package.sha.SHA256(
			user.externalServices.magister.credentials.password
		);

		if (hash === digest) {
			return user._id;
		}
	}

	return null;
};
