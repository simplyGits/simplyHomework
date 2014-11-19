# Router.map ->
# 	@route "email",
# 		action: ->
# 			req = @request
# 			res = @response

# 			if req.method is "POST"
# 				data = ""
# 				req.on "data", (chunk) -> data += chunk

# 				req.on "end", ->
# 						Email.send
# 							from: "simplyHomework <hello@simplyApps.nl>"
# 							to: mail
# 							subject: "mai"
# 							html: getMail text

# 				res.writeHead 200, "Content-Type": "text/plain"
# 				res.end "OK."

# 			else
# 				res.writeHead 405, "Content-Type": "text/plain"
# 				res.end "Use POST (you used #{req.method})"