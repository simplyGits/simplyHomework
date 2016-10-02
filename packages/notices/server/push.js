/* global ChatRooms, ChatMessages, Kadira, getUserField */
import onesignal from 'meteor/onesignal'

// TODO: sync dismissal
function notifyMessages (userId, chatRoomId) {
	const messages = ChatMessages.find({
		chatRoomId: chatRoomId,
		creatorId: {
			$ne: userId,
		},
		readBy: {
			$ne: userId,
		},
	}, {
		sort: {
			time: 1,
		},
	})

	if (
		messages.count() === 0 ||
		!getUserField(userId, 'settings.notifications.notif.chat', true)
	) {
		return
	}

	const chatRoom = ChatRooms.findOne(chatRoomId)

	const body = messages.fetch().map(m => {
		let prefix = ''
		if (chatRoom.type !== 'private') {
			const u = Meteor.users.findOne(m.creatorId)
			const name = u != null ?
				`${u.profile.firstName} ${u.profile.lastName}` :
				'Iemand'
			prefix = `${name}: `
		}

		return prefix + m.content
	}).join('\n')

	onesignal.sendNotification(userId, body, {
		title: chatRoom.getSubject(userId),
		picture: chatRoom.getPicture(userId, 500),
		url: Meteor.absoluteUrl(`chat/${chatRoomId}`),
	})
}

const infos = [] // { chatRoomId, userId, count }
function queueTick () {
	for (const info of infos) {
		if (++info.count < 5) {
			continue
		}

		_.pull(infos, info)
		try {
			notifyMessages(info.userId, info.chatRoomId)
		} catch (err) {
			Kadira.trackError(
				'notices-push',
				err.message,
				{ stacks: err.stack }
			)
		}
	}

	Meteor.setTimeout(queueTick, 1000)
}
queueTick()

Meteor.startup(function () {
	let loading = true

	ChatRooms.find({}, {
		fields: {
			_id: 1,
			lastMessageTime: 1,
			users: 1,
		},
	}).observe({
		changed(newDoc, oldDoc) {
			const time = doc => doc.lastMessageTime.getTime()
			if (loading || time(oldDoc) === time(newDoc)) {
				return
			}

			for (const userId of newDoc.users) {
				const has = infos.some(i => {
					return i.userId === userId && i.chatRoomId === newDoc.id
				})

				if (!has) {
					infos.push({
						chatRoomId: newDoc._id,
						userId: userId,
						count: 0,
					})
				}
			}
		},
	})

	loading = false
})
