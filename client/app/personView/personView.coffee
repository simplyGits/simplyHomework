sameUser = -> Meteor.userId() is Router.current().data()._id
sharedHours = new ReactiveVar []

status = ->
	s = Router.current().data().status

	res = null
	if s.idle
		res = "#FF9800"
	else if s.online
		res = "#4CAF50"
	else
		res = "#EF5350"

	$("meta[name='theme-color']").attr "content", res.backColor

	return res

Template.personView.helpers
	backColor: -> status()
	sameUser: sameUser

Template.personView.events
	"click button#chatButton": -> ChatManager.openUserChat @

Template.personView.rendered = ->
	@autorun ->
		Router.current()._paramsDep.depend()
		Meteor.defer -> $('[data-toggle="tooltip"]').tooltip
			container: "body"
			placement: "bottom"

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
		return if sameUser()
		appointments = magisterAppointment new Date(), new Date().addDays(7)

		sharedHours.set _.filter appointments, (a) ->
			currentUserHasHour = a.__groupInfo()?
			personHasHour = _.any Router.current().data().profile.groupInfos, (gi) -> gi.group is a.description()

			return currentUserHasHour and personHasHour
