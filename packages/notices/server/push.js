/* global ChatRooms, ChatMessages, Kadira */
import onesignal from 'meteor/onesignal'

// TODO: sync dismissal
function notifyMessages (chatRoomId) {
	const chatRoom = ChatRooms.findOne(chatRoomId)

	for (const userId of chatRoom.users) {
		const messages = ChatMessages.find({
			chatRoomId: chatRoomId,
			creatorId: {
				$ne: userId,
			},
			readBy: {
				$ne: userId,
			},
		})

		if (messages.count() === 0) {
			continue
		}

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
}

const infos = {} // key: chatRoomId, val: count
function queueTick () {
	for (const chatRoomId in infos) {
		if (++infos[chatRoomId] < 5) {
			continue
		}

		delete infos[chatRoomId]
		try {
			notifyMessages(chatRoomId)
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
		},
	}).observeChanges({
		changed(id) {
			if (loading) {
				return
			}

			if (infos[id] == null) {
				infos[id] = 0
			}
		},
	})

	loading = false
})
