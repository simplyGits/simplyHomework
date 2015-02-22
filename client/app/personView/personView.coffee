sameUser = -> Meteor.userId() is Router.current().data()._id
sharedHours = new ReactiveVar []

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

Template.personView.events
	"click button.chatButton": -> ChatManager.openUserChat @

Template.personView.rendered = ->
	@autorun ->
		Router.current()._paramsDep.depend()
		Meteor.defer -> $('[data-toggle="tooltip"]').tooltip container: "body"

Template.personSharedHours.helpers
	days: ->
		return _(sharedHours.get())
			.uniq (a) -> a.begin().date().getTime()
			.sortBy (a) -> a.begin().getDay() + 1
			.map (a) ->
				return {
					name: Helpers.cap DayToDutch Helpers.weekDay a.begin().date()
					hours: _.filter sharedHours.get(), (x) -> EJSON.equals x.begin().date(), a.begin().date()
				}
			.value()

Template.personSharedHours.rendered = ->
	@autorun ->
		# appointments = magisterAppointment new Date(), new Date().addDays(7)
		appointments = magisterAppointment new Date().addDays(-14), new Date().addDays(-7)

		sharedHours.set _.filter appointments, (a) ->
			currentUserHasHour = a.__groupInfo?
			personHasHour = _.any Router.current().data().profile.groupInfos, (gi) -> gi.group is a.description()

			return currentUserHasHour and personHasHour
