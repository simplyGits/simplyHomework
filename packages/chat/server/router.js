/* global Picker, ChatRooms */
import request from 'request';

Picker.route('/chat/pic/:uid/:cid/:size?', function (params, req, res) {
	const err = (code, str) => {
		res.writeHead(code, { 'Content-Type': 'text/plain' });
		res.end(str);
	}

	const chatRoom = ChatRooms.findOne(params.cid);
	if (chatRoom == null) {
		err(404, 'no chatroom found with given id');
		return;
	}

	let size = Number.parseInt(params.size, 10);
	if (Number.isNaN(size)) {
		size = 100;
	}

	let url = chatRoom.getPicture(params.uid, size);
	if (_.isEmpty(url)) {
		url = 'https://app.simplyhomework.nl/images/app_icon/192.png';
	}

	if (url.includes(';base64')) {
		const match = /^data:([^;]+);base64,(.+)$/.exec(url);
		const mediatype = match[1];
		const buf = Buffer.from(match[2], 'base64');

		res.writeHead(200, { 'Content-Type': mediatype });
		res.end(buf);
	} else {
		request({
			method: 'get',
			url,
		}).pipe(res);
	}
});
