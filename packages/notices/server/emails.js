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
		const toString = (g) => g.toString().replace('.', ',')

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
						grade: toString(grade),
						passed: grade.passed,
						average: toString(GradeFunctions.getEndGrade(c._id, userId)),
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

NoticeMails = {
	projects(projectId, addedUserId, adderUserId) {
		const added = Meteor.users.findOne(addedUserId)
		const setting = added.settings.devSettings.emailNotifications
		if (setting !== true) {
			return;
		}

		const project = Projects.findOne(projectId)
		const adder = Meteor.users.findOne(adderUserId)
		try {
			const html = Promise.await(emails.project({
				projectName: project.name,
				projectUrl: Meteor.absoluteUrl(`project/${projectId}`),
				personName: `${adder.profile.firstName} ${adder.profile.lastName}`,
			}))
			sendEmail(added, 'Toegevoegd aan project', html)
		} catch (err) {
			Kadira.trackError(
				'notices-emails',
				err.message,
				{ stacks: err.stack }
			)
		}
	}
}
