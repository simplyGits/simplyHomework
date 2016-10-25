/* global ZermeloBinding, getClassInfos, CalendarItem, ServiceUpdate, Schools */

'use strict'
import { createSession, loginBySessionInfo } from 'zermelo.js'
import { AuthError } from 'meteor/simply:external-services-connector'
import { LRU } from 'meteor/simply:lru'

// REVIEW Do we want this?
const log = ZermeloBinding.log

const cache = LRU({
	max: 50,
	maxAge: null,
})

/**
 * Creates data for the user with given `userId` with the given
 * parameters.
 *
 * @method createData
 * @param {String} schoolid
 * @param {String} authcode
 * @param {String} userId The ID of the user to save the info to.
 * @throws {AuthError} Throws an AuthError when the given the given login credentials are incorrect.
 * @throws {Error} Throws an error containing more info when an unknown error occured.
 */
ZermeloBinding.createData = function (schoolid, authcode, userId) {
	check(schoolid, String)
	check(authcode, String)
	check(userId, String)

	if (
		schoolid.length === 0 ||
		authcode.length === 0
	) {
		throw new AuthError('schoolid and authcode required')
	}

	try {
		const sessionInfo = Promise.await(createSession(schoolid, authcode))
		ZermeloBinding.storedInfo(userId, { schoolid, sessionInfo })
	} catch (e) {
		throw new AuthError(e.message)
	}
}

/**
 * @method getZermeloObject
 * @param {String} userId
 * @return {Zermelo}
 */
function getZermeloObject (userId) {
	check(userId, String)

	const data = ZermeloBinding.storedInfo(userId)
	if (_.isEmpty(data)) {
		cache.del(userId)
		throw new Error('No credentials found.')
	}

	let zermelo = cache.get(userId)
	if (zermelo === undefined) {
		zermelo = loginBySessionInfo(data.schoolid, data.sessionInfo)
		zermelo.school = Promise.await(zermelo.school())
		cache.set(userId, zermelo)
	}
	return zermelo
}

function prefixId (zermelo, ...args) {
	let res = zermelo.school.id
	for (const arg of args) {
		res += '_' + arg
	}
	return res
}

ZermeloBinding.getCalendarItems = function (userId, from, to) {
	check(userId, String)

	const zermelo = getZermeloObject(userId)
	const appointments = Promise.await(zermelo.appointments(from, to))
	const calendarItems = []
	const classInfos = getClassInfos(userId)

	for (const appointment of appointments) {
		const classInfo = classInfos.find(i => {
			const abbr = i.externalInfo.abbreviation
			return (
				abbr != null &&
				abbr.toLowerCase() === appointment.subjects[0].toLowerCase()
			)
		})
		const classId = classInfo && classInfo.id

		const calendarItem = new CalendarItem(
			userId,
			appointment.subjects[0],
			appointment.start,
			appointment.end,
			classId || undefined
		)

		calendarItem.externalInfo = {
			id: prefixId(zermelo, appointment.id),
			editable: false,
		}
		calendarItem.scrapped = appointment.isCancelled
		calendarItem.schoolHour = appointment.beginBySchoolHour
		calendarItem.location = appointment.locations[0]
		calendarItem.type = 'lesson'

		if (!_.isEmpty(calendarItem.remark)) {
			calendarItem.content = {
				type: appointment.type === 'exam' ? 'exam' : 'information',
				description: calendarItem.remark,
			}
		}
		// TODO: teacher

		calendarItems.push(calendarItem)
	}

	return {
		calendarItems,
		absenceInfos: [],
		files: [],
	}
}

ZermeloBinding.getPersonClasses = function (userId) {
	check(userId, String)

	// REVIEW: can we do something like this with the Zermelo API?
}

ZermeloBinding.getProfileData = function (userId) {
	check(userId, String)

	const zermelo = getZermeloObject(userId)
	const userInfo = Promise.await(zermelo.userInfo())
	const school = Schools.findOne({
		name: zermelo.school.name,
	})

	return {
		nameInfo: {
			firstName: userInfo.firstName,
			lastName: userInfo.lastName,
		},
		schoolId: school ? school._id : undefined,
	}
}

ZermeloBinding.getUpdates = function (userId) {
	check(userId, String)

	const zermelo = getZermeloObject(userId)
	const announcements = Promise.await(zermelo.announcements())
	return announcements.map(a => {
		const update = new ServiceUpdate(
			a.title,
			a.content,
			userId,
			ZermeloBinding.name,
			prefixId(zermelo, a.id)
		)

		update.date = a.start

		return update
	})
}
