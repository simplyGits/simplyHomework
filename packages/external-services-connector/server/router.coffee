request = Npm.require 'request'

parseCookies = (str = '') ->
	res = {}
	str
		.split /[\s;]+/g
		.forEach (cookie) ->
			splitted = cookie.split '='
			res[splitted[0]] = splitted[1]
	res

Picker.route '/f/:fid', (params, req, res) ->
	err = (code, str) ->
		res.writeHead code, 'Content-Type': 'text/plain'
		res.end str

	cookies = parseCookies req.headers.cookie
	token = cookies['meteor_login_token']
	unless token?
		err 401, 'not logged in'
		return undefined

	userId = Meteor.users.findOne({
		"services.resume.loginTokens.hashedToken": Accounts._hashLoginToken token
	}, {
		fields: _id: 1
	})?._id
	unless userId?
		err 404, 'no user found with provided logintoken'
		return undefined

	file = Files.findOne
		_id: params.fid
		userIds: userId
	unless file?
		err 404, 'file not found'
		return undefined

	info = file.downloadInfo
	if info.redirect?
		res.writeHead 301, 'Location': info.redirect
		res.end()
	else if info.path? and info.requireauth is false
		request(
			method: 'get'
			url: info.path
		).pipe res
	else
		service = _.find Services, name: file.fetchedBy
		unless service?
			err 500, 'service not found'
			return undefined

		service.getFile(userId, info).pipe(res)

	trackFileDownload params.fid
	undefined
