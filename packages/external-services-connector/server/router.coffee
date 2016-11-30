request = require 'request'
{ Services } = require './connector.coffee'

parseCookies = (str = '') ->
	res = {}
	str
		.split /[\s;]+/g
		.forEach (cookie) ->
			splitted = cookie.split '='
			res[splitted[0]] = splitted[1]
	res

# REVIEW: I removed _all_ auth. Do we want to require auth for this?
Picker.route '/f/:fid/:uid?', (params, req, res) ->
	err = (code, str) ->
		res.writeHead code, 'Content-Type': 'text/plain'
		res.end str

	userId = params.uid
	unless userId?
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

	file = Files.findOne params.fid
	unless file?
		err 404, 'file not found'
		return undefined

	info = file.downloadInfo
	if info.redirect?
		res.writeHead 301, 'Location': info.redirect
		res.end()
	else
		res.setHeader 'Content-disposition', [ 'attachment', "filename=#{file.name}" ]

		if info.path? and info.requireauth is false
			request(
				method: 'get'
				url: info.path
			).pipe res
		else
			service = _.find Services, name: file.fetchedBy
			unless service?
				err 500, 'service not found'
				return undefined

			try
				service.getFile(userId, info).pipe(res)
			catch e
				console.error 'error while getting file from service', e
				err 500, 'internal server error'

	trackFileDownload params.fid
	undefined
