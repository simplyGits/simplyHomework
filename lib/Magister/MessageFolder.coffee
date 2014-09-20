findQueries = (queries) ->
	final = ""

	if _.any(["read", "gelezen"], (x) -> Helpers.contains queries, x, yes)
		final += "&gelezen=true"
	else if _.any(["unread", "ongelezen"], (x) -> Helpers.contains queries, x, yes)
		final += "&gelezen=false"

	if (result = /(skip \d+)|(sla \d+ over)/ig.exec(queries))?
		numbers = /\d+/.exec(result[0])[0]
		final += "&skip=#{numbers}"

	return final

class @MessageFolder
	constructor: (@_magisterObj, _local = no) -> throw new Error("You can only get MessageFolders from a Magister instance") unless _local

	messages: (limit, queries, callback) ->
		limit = _.find(arguments, (a) -> _.isNumber a) ? 10
		queries = _.find(arguments, (a) -> _.isString a) ? ""
		
		callback = _.find(arguments, (a) -> _.isFunction a)
		throw new Error("Callback is null") unless callback?

		url = "#{@_magisterObj.magisterSchool.url}/api/personen/#{@_magisterObj._id}/berichten?mapId=#{@id}&top=#{limit}#{findQueries queries}"

		@_magisterObj.http.get url, {}, (error, result) =>
			if error?
				callback error, null
			else
				callback null, (Message._convertRaw(@_magisterObj, m) for m in EJSON.parse(result.content).Items)

	messageFolders: (query, callback) ->
		@_magisterObj.http.get "#{@_magisterObj.magisterSchool.url}/api/personen/#{@_magisterObj._id}/berichten/mappen?parentId=#{@id}", {},
			(error, result) =>
				if error?
					callback error, null
				else
					callback = _.find(arguments, (a) -> _.isFunction a) ? (->)
					messageFolders = MessageFolder._convertRaw(@_magisterObj, mF) for mF in EJSON.parse(result.content).Items

					if _.isString(query) and query isnt ""
						result = _.where messageFolders, (mF) -> Helpers.contains mF.name, query, yes
					else
						result = messageFolders

					callback null, result

	@_convertRaw: (magisterObj, raw) ->
		obj = new MessageFolder magisterObj, yes

		obj.name = raw.Naam
		obj.unreadMessagesCount = raw.OngelezenBerichten
		obj.id = raw.Id
		obj.parentId = raw.ParentId

		return obj