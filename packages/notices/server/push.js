/* global ChatRooms, ChatMessages, picture */
import onesignal from 'meteor/onesignal'

// TODO: sync dismissal
function notifyMessage (userId, message) {
	const sender = Meteor.users.findOne(message.creatorId)
	const chatRoom = ChatRooms.findOne(message.chatRoomId)
	const title = chatRoom.type === 'private' ?
		chatRoom.getSubject(userId) :
		`${sender.profile.firstName} in ${chatRoom.getSubject(userId)}`

	onesignal.sendNotification(userId, message.content, {
		title: title,
		picture: picture(sender, 500),
		url: Meteor.absoluteUrl(`chat/${message.chatRoomId}`),
	})
}

let infos = [] // { userId, id, count }
Meteor.setInterval(function () {
	for (const obj of infos) {
		if (++obj.count === 5) {
			const message = ChatMessages.findOne({
				_id: obj.id,
				readBy: {
					$ne: obj.userId,
				},
			})
			if (message != null) {
				notifyMessage(obj.userId, message)
			}
			infos = _.without(infos, obj)
		}
	}
}, 1000)

Meteor.startup(function () {
	let loading = true

	ChatMessages.find({}).observe({
		added(doc) {
			if (loading) {
				return
			}

			const chatRoom = ChatRooms.findOne(doc.chatRoomId)
			const userIds = _.reject(chatRoom.users, doc.creatorId)
			for (const userId of userIds) {
				infos.push({
					userId: userId,
					id: doc._id,
					count: 0,
				})
			}
		},
	})

	loading = false
})
