sameUser = -> Meteor.userId() is Router.current().data()._id

status = ->
	s = Router.current().data().status
	res = null
	if s.idle
		res = backColor: "#FF9800", borderColor: "#E65100"
	else if s.online
		res = backColor: "#4CAF50", borderColor: "#1B5E20"
	else
		res = backColor: "#EF5350", borderColor: "#B71C1C"
	$("meta[name='theme-color']").attr "content", res.backColor
	return res

Template.personView.helpers
	backColor: -> status().backColor
	borderColor: -> status().borderColor
	sameUser: sameUser

Template.personView.rendered = ->
	@autorun ->
		Router.current()._paramsDep.depend()
		Meteor.defer -> $('[data-toggle="tooltip"]').tooltip container: "body"
