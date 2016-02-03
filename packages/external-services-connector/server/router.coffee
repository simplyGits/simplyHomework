request = Npm.require 'request'

parseCookies = (str) ->
	res = {}
	str
		.split /[\s;]+/g
		.forEach (cookie) ->
			splitted = cookie.split '='
			res[splitted[0]] = splitted[1]
	res

Picker.route '/su/:suid/file/:fid', (params, req, res) ->
	err = (str) ->
		res.writeHead 403, 'Content-Type': 'text/plain'
		res.end str

	cookies = parseCookies req.headers.cookie
	token = cookies['meteor_login_token']
	unless token?
		err 'not logged in'
		return undefined

	userId = Meteor.users.findOne({
		"services.resume.loginTokens.hashedToken": Accounts._hashLoginToken token
	}, {
		fields: _id: 1
	})?._id
	unless userId?
		err 'no user found with provided logintoken'
		return undefined

	studyUtil = StudyUtils.findOne
		_id: params.suid
		userIds: userId
	unless studyUtil?
		err 'studyutil not found'
		return undefined

	file = _.find studyUtil.files, _id: params.fid
	unless file?
		err 'file not found'
		return undefined

	info = file.downloadInfo
	if info.path? and info.requireauth is false
		request(
			method: 'get'
			url: info.path
		).pipe res
	else
		service = _.find Services, name: file.fetchedBy
		unless service?
			err 'service not found'
			return undefined

		if info.redirect?
			res.writeHead 301, 'Location': info.redirect
			res.end()
		else
			service.getFile(userId, info).pipe(res)

	undefined
