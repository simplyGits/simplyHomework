/* global Messages, Picker */

import { sendEmptyGif, emptyGifBufferLength } from 'emptygif'

Picker.route('/_track/:uid/messageread/:mid', function (params, req, res) {
	Meteor.defer(function () {
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
