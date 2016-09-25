/* global Messages, Picker, getUserField */

import { sendEmptyGif, emptyGifBufferLength } from 'emptygif'

Picker.route('/_track/:uid/messageread/:mid', function (params, req, res) {
	Meteor.defer(function () {
		if (!getUserField(
			params.uid,
			'settings.devSettings.messageEmailNotifMarkRead',
			false
		)) {
			return
		}

		Messages.update({
			_id: params.mid,
			fetchedFor: params.uid,
		}, {
			$addToSet: { readBy: params.uid },
		})
	})

	sendEmptyGif(req, res, {
		'Content-Type': 'image/gif',
		'Content-Length': emptyGifBufferLength,
	})
})
