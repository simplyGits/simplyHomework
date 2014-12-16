currentProject = -> Router.current().data()

@getParticipants = ->
	tmp = []
	for participant, i in Meteor.users.find(_id: $in: currentProject().participants).fetch()
		tmp.push _.extend participant,
			__statusColor: if participant.status.idle then "#FF851B" else if participant.status.online then "#2ECC40" else "#FF4136"
	return tmp

@getOthers = ->
	tmp = []
	for other, i in Meteor.users.find(_id: $nin: currentProject().participants).fetch()
		tmp.push _.extend other,
			fullName: "#{other.profile.firstName} #{other.profile.lastName}"
	return tmp

fileTypes =
	document:
		fileTypeIconClass: "file-text-o"
		fileTypeColor: "#32A8CE"
	presentation:
		fileTypeIconClass: "file-powerpoint-o"
		fileTypeColor: "#F4B400"
	spreadsheet:
		fileTypeIconClass: "file-excel-o"
		fileTypeColor: "#0F9D58"
	pdf:
		fileTypeIconClass: "file-pdf-o"
		fileTypeColor: "#CF1312"

@personsEngine = new Bloodhound
	name: "persons"
	datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.fullName
	queryTokenizer: Bloodhound.tokenizers.whitespace
	local: []

Template.projectView.rendered = =>
	Deps.autorun =>
		return unless Router.current().route.getName() is "projectView"
		@personsEngine.clear()
		@personsEngine.add getOthers()

Template.projectView.helpers
	files: ->
		tmp = []
		for i in [1..100]
			type = _.first _.shuffle fileTypes
			tmp.push { name: "kaas ##{i}", fileTypeIconClass: type.fileTypeIconClass, fileTypeColor: type.fileTypeColor }
		return tmp
	persons: -> _.reject getParticipants(), (p) -> EJSON.equals p._id, Meteor.userId()

	showRightHeader: -> if currentProject().participants.length is 1 then false else true
	friendlyDeadline: ->
		return "" unless currentProject().deadline?
		day = DayToDutch Helpers.weekDay currentProject().deadline
		time = "#{currentProject().deadline.getHours()}:#{currentProject().deadline.getMinutes()}"

		return (switch Helpers.daysRange new Date(), currentProject().deadline
			when -6, -5, -4, -3 then "Afgelopen #{day}"
			when -2 then "Eergisteren"
			when -1 then "Gisteren"
			when 0 then "Vandaag"
			when 1 then "Morgen"
			when 2 then "Overmorgen"
			when 3, 4, 5, 6 then "Aanstaande #{day}"
			else "#{Helpers.cap day} #{DateToDutch(currentProject().deadline, no)}") + " " + time
	heightOffset: -> if has("noAds") then 260 else 350

Template.projectView.events
	"click #addFileIcon": ->
		notify "Hey"
	"click #addPersonIcon": ->
		$("#personNameInput").val ""
		$("#addParticipantModal").modal backdrop: no

Template.addParticipantModal.rendered = ->
	personsEngine.initialize()

	$("#personNameInput").typeahead(null,
		source: personsEngine.ttAdapter()
		displayKey: "fullName"
		templates:
			suggestion: (data) -> "<img class=\"lastChatSenderPicture\" src=\"#{gravatar data}\" width=\"50\" height=\"50\"><span class=\"personSuggestionName\"<b>#{data.fullName}</b>"
	).on "typeahead:selected", (obj, datum) -> Session.set "currentSelectedPersonDatum", datum

addUser = ->
	Projects.update currentProject()._id, $push: participants: Session.get("currentSelectedPersonDatum")._id
	$("#addParticipantModal").modal "hide"
	notify Locals["nl-NL"].ProjectPersonAddedNotice(Session.get("currentSelectedPersonDatum").profile.firstName), "notice"

Template.addParticipantModal.events
	"click #goButton": addUser
	"keydown #personNameInput": (event) -> addUser() if event.which is 13

Template.fileRow.events
	"click": (event) ->
		target = $(event.target)
		ripple = target.find(".ripple")

		ripple.removeClass "animate"

		unless ripple.height() or ripple.width()
			diameter = Math.max target.outerWidth(), target.outerHeight()
			ripple.css height: diameter, width: diameter

		x = event.pageX - target.offset().left - ripple.width() / 2
		y = event.pageY - target.offset().top - ripple.height() / 2

		ripple.css(top: "#{y}px", left: "#{x}px").addClass "animate"

Template.personRow.events
	"click": (event) -> Router.go "personView", @ unless $(event.target).hasClass "removePersonButton"

	"click .removePersonButton": ->
		alertModal "Zeker weten?", Locals["nl-NL"].ProjectPersonRemovalMessage(@profile.firstName), DialogButtons.OkCancel, { main: "Is de bedoeling", second: "heh!?" }, { main: "btn-danger" }, main: =>
			Projects.update currentProject()._id, $pull: participants: @_id
			notify Locals["nl-NL"].ProjectPersonRemovedNotice(@profile.firstName), "notice"