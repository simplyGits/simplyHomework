url = "http://www.corsproxy.com/www.telegraaf.nl/snelnieuws/index.jsp?sec=binnenland"

@getTelegraaf = (callback) ->
	$.get url, {}, (result) ->
		items = $(result).find("#main .item a")

		results = []
		left = items.length
		pushResult = (result) ->
			results.push result
			left--
			callback(results) if left is 0

		for a in items
			$.get "http://www.corsproxy.com/#{a.href[7..]}", {}, (result) ->
				x = $(result)
				obj = {}

				obj.title = x.find("#artikel h1").text().trim()

				location = x.find(".location").text()
				obj.location = location.substring(0, location.length - 3)
				
				obj.url = a.href

				pushResult obj