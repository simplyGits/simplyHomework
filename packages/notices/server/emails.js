/* global Kadira, Grades, Projects, updateGrades, SyncedCron, Classes,
   GradeFunctions */

import emails from 'meteor/emails'

// TODO: have a central place for the default options of notifications, just
// like the 'privacy' package has. Currently if we want to change the default of
// notifications options we have to do that on various places. Would be nice if
// it would just be one.

/**
 * @method sendEmail
 * @param {User} user
 * @param {String} subject
 * @param {String} html
 */
function sendEmail (user, subject, html) {
	Email.send({
		from: 'simplyHomework <hello@simplyApps.nl>',
		to: user.emails[0].address,
		subject: `simplyHomework | ${subject}`,
		html,
	})
}

SyncedCron.add({
	name: 'Notify new grades',
	schedule: (parser) => parser.recur().on(3).hour(),
	job: function () {
		const users = Meteor.users.find({
			'profile.firstName': { $ne: '' },
			'settings.devSettings.emailNotifications': true,
		}).fetch()

		users.forEach((user) => {
			const userId = user._id

			updateGrades(userId, false)

			const grades = Grades.find({
				ownerId: userId,
				classId: { $exists: true },
				dateFilledIn: { $gte: Date.today().addDays(-1) },
			}, {
				fields: {
					_id: 1,
					classId: 1,
					dateFilledIn: 1,
					gradeStr: 1,
					passed: 1,
					ownerId: 1,
				},
			})

			grades.forEach((grade) => {
				if (user.status.lastLogin.date > grade.dateFilledIn) {
					// user probably has already seen the grade when he logged in on
					// simplyHomework, no need to send a mail.
					return
				}

				const c = Classes.findOne(grade.classId)

				try {
					const html = Promise.await(emails.cijfer({
						className: c.name,
						classUrl: Meteor.absoluteUrl(`class/${c._id}`),
						grade: grade.gradeStr,
						passed: grade.passed,
						average: GradeFunctions.getEndGrade(c._id, userId),
					}))
					sendEmail(user, `Nieuw cijfer voor ${c.name}`, html)
				} catch (err) {
					Kadira.trackError(
						'notices-emails',
						err.message,
						{ stacks: err.stack }
					)
				}
			})
		})
	},
})

Meteor.startup(function () {
	let startingObservers = true

	Projects.find({
		participants: { $ne: [] },
	}, {
		fields: {
			_id: 1,
			participants: 1,
			name: 1,
		},
	}).observe({
		changed(newDoc, oldDoc) {
			if (startingObservers) {
				return
			}

			const oldParticipants = oldDoc.participants
			const newParticipants = newDoc.participants
			const addedParticipants = _.difference(newParticipants, oldParticipants)

			addedParticipants.forEach((userId) => {
				const user = Meteor.users.findOne(userId)
				const setting = user.settings.devSettings.emailNotifications
				if (setting !== false) {
					return;
				}

				try {
					const html = Promise.await(emails.project({
						projectName: newDoc.name,
						projectUrl: Meteor.absoluteUrl(`project/${newDoc._id}`),
						personName: `${user.profile.firstName} ${user.profile.lastName}`,
					}))
					sendEmail(user, 'Toegevoegd aan project', html)
				} catch (err) {
					Kadira.trackError(
						'notices-emails',
						err.message,
						{ stacks: err.stack }
					)
				}
			})
		},
	})

	startingObservers = false
})
