root = @
currentProject = -> Router.current().data()
cachedProjectFiles = new ReactiveVar {}

@getParticipants = ->
	tmp = []
	for participant, i in Meteor.users.find({_id: $in: currentProject().participants ? []}, sort: "profile.firstName": 1).fetch()
		tmp.push _.extend participant,
			__statusColor: if participant.status.idle then "#FF851B" else if participant.status.online then "#2ECC40" else "#FF4136"
			__isOwner: Router.current().data().ownerId is Meteor.userId()
	return tmp

@getOthers = ->
	tmp = []
	for other, i in Meteor.users.find(_id: $nin: currentProject().participants ? []).fetch()
		tmp.push _.extend other,
			fullName: "#{other.profile.firstName} #{other.profile.lastName}"
	return tmp

fileTypes =
	"application/vnd.google-apps.document":
		fileTypeIconClass: "file-text-o"
		fileTypeColor: "#32A8CE"
	"application/vnd.google-apps.presentation":
		fileTypeIconClass: "file-powerpoint-o"
		fileTypeColor: "#F4B400"
	"application/vnd.google-apps.spreadsheet":
		fileTypeIconClass: "file-excel-o"
		fileTypeColor: "#0F9D58"
	"application/pdf":
		fileTypeIconClass: "file-pdf-o"
		fileTypeColor: "#CF1312"
	"image/":
		fileTypeIconClass: "file-image-o"
		fileTypeColor: "#85144B"

@personsEngine = new Bloodhound
	name: "persons"
	datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.fullName
	queryTokenizer: Bloodhound.tokenizers.whitespace
	local: []

Template.projectView.rendered = ->
	@autorun ->
		window.personsEngine.clear()
		window.personsEngine.add getOthers()

	loading = []
	@autorun ->
		return unless driveLoaded.get()

		x = cachedProjectFiles.get()
		fileIds = _.reject currentProject().driveFileIds, (s) -> s in x or _.contains loading, s
		needed = fileIds.length

		push = (r) ->
			x[r.id] = r
			if --needed is 0 then cachedProjectFiles.set x

		for driveFileId in fileIds
			loading.push driveFileId
			gapi.client.drive.files.get(fileId: driveFileId).execute (r) ->
				push _.extend r, fileTypes[_(fileTypes).keys().find((s) -> r.mimeType.indexOf(s) is 0)] ? { fileTypeIconClass: "question-circle", fileTypeColor: "#001f3f" }

				_.remove loading, r.id

	Mousetrap.bind "a p", (e) ->
		e.preventDefault()
		$("#addParticipantModal").modal backdrop: no
		$("#personNameInput").focus()

Template.projectView.helpers
	files: ->
		_(cachedProjectFiles.get())
			.values()
			.filter((f) -> _.contains currentProject().driveFileIds, f.id)
			.sortBy((f) -> new Date(Date.parse f.modifiedDate).getTime())
			.reverse()
			.value()
	persons: -> _.reject getParticipants(), (p) -> EJSON.equals p._id, Meteor.userId()
	isOwner: -> Router.current().data().ownerId is Meteor.userId()

	showRightHeader: -> (currentProject().participants ? []) isnt 1
	overDue: -> if not currentProject().deadline? or currentProject().deadline > new Date() then "initial" else "darkred"
	heightOffset: -> if has("noAds") then 260 else 315

Template.projectView.events
	"click #addFileIcon": ->
		onPickerResult (r) ->
			return unless r.action is "picked"
			cb = ->
				Projects.update currentProject()._id, $push: driveFileIds: r.docs[0].id, (e) ->
					if e?
						notify "Bestand kan niet worden toegevoegd", "error"
						Kadira.trackError "Remove-add-file", e.message, stacks: e.stack
					else notify "#{r.docs[0].title} toegevoegd.", "notice"

			setPermissions = ->
				if _.any(r.docs[0].permissions, (p) -> p.type is "anyone" and p.role is "writer") then cb()
				else
					gapi.client.drive.permissions.insert(
						fileId: r.docs[0].id
						resource:
							type: "anyone"
							role: "writer"
							withLink: yes
					).execute (r) ->
						if r.error?
							notify "Bestand kan niet worden toegevoegd", "error"
							Kadira.trackError "Drive-client", r.error.message, stacks: EJSON.stringify r
						else cb()

			if (r.docs[0].type isnt "document" and r.docs[0].mimeType.indexOf("openxmlformats") is -1) or _(fileTypes).keys().contains(r.docs[0].mimeType) then setPermissions()
			else
				gapi.client.drive.files.copy(
					fileId: r.docs[0].id
					convert: yes
					resource:
						title: (
							if (val = r.docs[0].name.replace(/[-_]/g, " ").split(".")).length is 1
								val[0]
							else
								_.initial(val)[0].join "."
						)
				).execute (res) ->
					if res.error?
						notify "Bestand kan niet worden toegevoegd", "error"
						Kadira.trackError "Drive-client", res.error.message, stacks: EJSON.stringify res
					else
						gapi.client.drive.files.delete(fileId: r.docs[0].id).execute()
						r.docs[0] = res
						setPermissions()

	"click #addPersonIcon": ->
		subs.subscribe "usersData"
		$("#personNameInput").val ""
		$("#addParticipantModal").modal backdrop: no

	"click #changeProjectIcon": ->
		ga "send", "event", "button", "click", "projectInfoChange"

		$("#changeDeadlineInput").datetimepicker
			locale: moment.locale()
			defaultDate: currentProject().deadline
			icons:
				time: "fa fa-clock-o"
				date: "fa fa-calendar"
				up: "fa fa-arrow-up"
				down: "fa fa-arrow-down"
				previous: "fa fa-chevron-left"
				next: "fa fa-chevron-right"

		ownClassesEngine = new Bloodhound
			name: "ownClasses"
			datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace d.name
			queryTokenizer: Bloodhound.tokenizers.whitespace
			local: classes().fetch()

		ownClassesEngine.initialize()

		$("#changeClassInput").typeahead(null,
			source: ownClassesEngine.ttAdapter()
			displayKey: "name"
		).on "typeahead:selected", (obj, datum) -> Session.set "currentSelectedClassDatum", datum

		$("#changeProjectModal").modal backdrop: false

	"click .projectInfoChatQuoteContainer": -> ChatManager.openProjectChat this

Template.changeProjectModal.events
	"click #goButton": ->
		name = $("#changeNameInput").val().trim()
		description = $("#changeDescriptionInput").val().trim()
		deadline = $("#changeDeadlineInput").data("DateTimePicker").getDate().toDate()
		classId = Session.get("currentSelectedClassDatum")?._id ? currentProject().__class()?._id

		Projects.update currentProject()._id, $set: { name, description, deadline, magisterId: currentProject().magisterId, classId }

		$("#changeProjectModal").modal "hide"

	"click #leaveProjectButton": ->
		id = currentProject()._id
		Router.go "app"
		Projects.update id, $pull: participants: Meteor.userId()

Template.addParticipantModal.rendered = ->
	personsEngine.initialize()

	$("#personNameInput").typeahead(null,
		source: personsEngine.ttAdapter()
		displayKey: "fullName"
		templates:
			suggestion: (data) -> "<img class=\"lastChatSenderPicture\" src=\"#{gravatar data}\" width=\"50\" height=\"50\"><span class=\"personSuggestionName\"<b>#{data.fullName}</b>"
	).on "typeahead:selected", (obj, datum) -> Session.set "currentSelectedPersonDatum", datum

addUser = ->
	# Handle cases where the user didn't select an autocomplete
	if Session.get("currentSelectedPersonDatum").fullName.toLowerCase().indexOf($("#personNameInput").val().toLowerCase()) is -1
		if (val = _.find getOthers(), (p) -> p.fullName.toLowerCase().indexOf($("#personNameInput").val().toLowerCase()) is 0)?
			Session.set "currentSelectedPersonDatum", val
		else
			shake "#addParticipantModal"
			return

	Projects.update currentProject()._id, $push: participants: Session.get("currentSelectedPersonDatum")._id
	$("#addParticipantModal").modal "hide"
	notify Locals["nl-NL"].ProjectPersonAddedNotice(Session.get("currentSelectedPersonDatum").profile.firstName), "notice"

Template.addParticipantModal.events
	"click #goButton": addUser
	"keydown #personNameInput": (event) -> addUser() if event.which is 13

Template.fileRow.events
	"click .removeFileButton": (event) ->
		event.preventDefault()
		Projects.update currentProject()._id, $pull: driveFileIds: @id, (e) =>
			if e?
				notify "Bestand kan niet worden verwijderd.", "error"
				Kadira.trackError "Remove-project-file", e.message, stacks: e.stack
			else notify "#{@title} verwijderd.", "notice"

Template.personRow.events
	"click": (event) -> Router.go "personView", this unless $(event.target).hasClass "removePersonButton"

	"click .removePersonButton": ->
		alertModal "Zeker weten?", Locals["nl-NL"].ProjectPersonRemovalMessage(@profile.firstName), DialogButtons.OkCancel, { main: "Is de bedoeling", second: "heh!?" }, { main: "btn-danger" }, main: =>
			Projects.update currentProject()._id, $pull: participants: @_id
			notify Locals["nl-NL"].ProjectPersonRemovedNotice(@profile.firstName), "notice"
