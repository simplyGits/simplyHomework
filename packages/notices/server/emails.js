import * as emails from 'simplyemail'

const settingsUrl = Meteor.absoluteUrl('settings')

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
	schedule: (parser) => parser.recur().on(2).hour(),
	job: function () {
		const grades = Grades.find({
			classId: { $exists: true },
			dateFilledIn: { $gte: Date.today().addDays(-1) },
		}, {
			fields: {
				_id: 1,
				classId: 1,
				dateFilledIn: 1,
				gradeStr: 1,
				passed: 1,
			},
		})

		grades.forEach((grade) => {
			const userId = grade.ownerId
			const user = Meteor.users.findOne(userId)

			if (user.status.lastLogin.date > grade.dateFilledIn) {
				// user probably has already seen the grade when he logged in on
				// simplyHomework, no need to send a mail.
				return
			}

			const c = Classes.findOne(grade.classId)

			emails.cijfer({
				className: c.name,
				classUrl: Meteor.absoluteUrl(`class/${c._id}`),
				grade: grade.gradeStr,
				passed: grade.passed,
				average: GradeFunctions.getEndGrade(c._id, userId),
				settingsUrl,
			}).then((html) => {
				sendEmail(user, `Nieuw cijfer voor ${c.name}`, html)
			}, (err) => {
				Kadira.trackError(
					'notices-emails',
					err.message,
					{ stacks: err.stack }
				)
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

			addedPersons.forEach((userId) => {
				const user = Meteor.users.findOne(userId)

				emails.project({
					projectName: newDoc.name,
					projectUrl: Meteor.absoluteUrl(`project/${newDoc._id}`),
					personName: `${user.profile.firstName} ${user.profile.lastName}`,
					settingsUrl,
				}).then((html) => {
					sendEmail(user, 'Toegevoegd aan project', html)
				}, (err) => {
					Kadira.trackError(
						'notices-emails',
						err.message,
						{ stacks: err.stack }
					)
				})
			})
		},
	})

	startingObservers = false
})
