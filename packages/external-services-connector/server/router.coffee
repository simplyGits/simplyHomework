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

Picker.route '/f/:fid', (params, req, res) ->
	err = (code, str) ->
		res.writeHead code, 'Content-Type': 'text/plain'
		res.end str

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
				service.getFile(info).pipe(res)
			catch e
				console.error 'error while getting file from service', e
				err 500, 'internal server error'

	trackFileDownload params.fid
	undefined
