cachedProjectFiles = new ReactiveVar {}

currentProject = ->
	id = FlowRouter.getParam 'id'
	Projects.findOne _id: id

# == Notes:
# - 2 methods for basicly the same thing is a bit ugly.
# - `__isOwner` is really badly designed, this looks like we specifiy if the
# 	root user object is the owner, but we specifiy if `Meteor.user()` is the
# 	owner.
getParticipants = ->
	Meteor.users.find {
		_id:
			$in: currentProject().participants ? []
			$ne: Meteor.userId()
	}, {
		sort: 'profile.firstName': 1
		transform: (u) -> _.extend u,
			__status: (
				if u.status?.idle then 'inactive'
				else if u.status?.online then 'online'
				else 'offline'
			)
			#__isOwner: Router.current().data().ownerId is Meteor.userId()
	}

getOthers = ->
	Meteor.users.find {
		_id: $nin: currentProject().participants ? []
	}, {
		transform: (u) -> _.extend u,
			fullName: "#{u.profile.firstName} #{u.profile.lastName}"
	}

fileTypes =
	'application/vnd.google-apps.document':
		fileTypeIconClass: 'file-text-o'
		fileTypeColor: '#32A8CE'
	'application/vnd.google-apps.presentation':
		fileTypeIconClass: 'file-powerpoint-o'
		fileTypeColor: '#F4B400'
	'application/vnd.google-apps.spreadsheet':
		fileTypeIconClass: 'file-excel-o'
		fileTypeColor: '#0F9D58'
	'application/pdf':
		fileTypeIconClass: 'file-pdf-o'
		fileTypeColor: '#CF1312'
	'image/':
		fileTypeIconClass: 'file-image-o'
		fileTypeColor: '#85144B'

Template.projectView.onCreated ->
	@autorun =>
		id = FlowRouter.getParam 'id'
		@subscribe 'project', id, onReady: =>
			p = Projects.findOne _id: id
			if p?
				@subscribe 'usersData', p.participants
				@subscribe 'status', _.reject p.participants, Meteor.userId()

				c = p.getClass()
				slide c._id if c?
				setPageOptions
					title: p.name
					color: c?.__color
			else
				notFound()

	loading = []
	@autorun =>
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

	Mousetrap.bind 'a p', ->
		showModal 'addParticipantModal'
		false

Template.projectView.onDestroyed ->
	Mousetrap.unbind 'a p'

Template.projectView.helpers
	project: currentProject

	files: ->
		_(cachedProjectFiles.get())
			.values()
			.filter (f) => _.contains @driveFileIds, f.id
			.sortBy (f) -> new Date(f.modifiedDate).getTime()
			.reverse()
			.value()
	persons: -> getParticipants()
	#isOwner: -> Router.current().data().ownerId is Meteor.userId()

	overdue: ->
		if @deadline? and @deadline < new Date
			'overdue'
		else
			''

Template.projectView.events
	"click #addFileIcon": ->
		# TODO: clean this mess up.
		onPickerResult (r) =>
			return unless r.action is "picked"
			cb = =>
				Projects.update @_id, $addToSet: driveFileIds: r.docs[0].id, (e) ->
					if e?
						notify "Bestand kan niet worden toegevoegd", "error"
						Kadira.trackError "Remove-add-file", e.message, stacks: e.stack
					else notify "#{r.docs[0].title} toegevoegd", "notice"

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
								_.initial(val).join '.'
						)
				).execute (res) ->
					if res.error?
						notify "Bestand kan niet worden toegevoegd", "error"
						Kadira.trackError "Drive-client", res.error.message, stacks: EJSON.stringify res
					else
						r.docs[0] = res
						setPermissions()

	"click #addPersonIcon": ->
		showModal 'addParticipantModal'

	"click #changeProjectIcon": ->
		ga 'send', 'event', 'changeProjectModal', 'open'

		showModal 'changeProjectModal', undefined, currentProject()

		$('#changeDeadlineInput').datetimepicker defaultDate: @deadline
	"click #chatButton": -> ChatManager.openProjectChat @_id

Template.changeProjectModal.helpers
	classes: -> classes()

Template.changeProjectModal.events
	'click #goButton': ->
		name = $('#changeNameInput').val().trim()
		description = $('#changeDescriptionInput').val().trim()
		deadline = $('#changeDeadlineInput').data('DateTimePicker').date().toDate()
		className = $('#changeClassInput').val()
		classId = Classes.findOne(name: className)?._id ? @getClass()?._id

		Projects.update @_id, $set: {
			name
			description
			deadline
			classId
		}

		ga 'send', 'event', 'changeProjectModal', 'save'
		$('#changeProjectModal').modal 'hide'

	'click #leaveProjectButton': ->
		FlowRouter.go 'overview'
		Projects.update @_id, $pull: participants: Meteor.userId()
		notify 'Project verlaten', 'notice'

Template.changeProjectModal.onRendered ->
	Meteor.typeahead.inject '#changeClassInput'

Template.addParticipantModal.helpers
	persons: -> getOthers().fetch()

Template.addParticipantModal.onCreated ->
	@subscribe 'usersData'

Template.addParticipantModal.onRendered ->
	Meteor.typeahead.inject '#personNameInput'

addUser = ->
	# Handle cases where the user didn't select an autocomplete
	selected = Session.get 'currentSelectedPersonDatum'
	$personNameInput = $ '#personNameInput'

	val = (
		if Helpers.contains selected?.fullName, $personNameInput.val(), yes
			selected
		else
			_.find getOthers().fetch(), (p) ->
				Helpers.contains p.fullName, $personNameInput.val(), yes
	)
	unless val?
		shake '#addParticipantModal'
		return

	Meteor.call 'addProjectParticipant', currentProject()._id, val._id, (e) ->
		$('#addParticipantModal').modal 'hide'
		if e?
			notify 'Onbekende fout, we zijn op de hoogte gesteld', 'error'
		else
			notify TAPi18n.__('projectPersonAddedNotice', val.profile.firstName), 'notice'

Template.addParticipantModal.events
	"click #goButton": addUser
	'keydown #personNameInput': (event) -> addUser() if event.which is 13

Template.fileRow.events
	"click .removeFileButton": (event) ->
		event.preventDefault()
		Projects.update currentProject()._id, $pull: driveFileIds: @id, (e) =>
			if e?
				notify "Bestand kan niet worden verwijderd", "error"
				Kadira.trackError "Remove-project-file", e.message, stacks: e.stack
			else notify "#{@title} verwijderd", "notice"

Template.personRow.events
	'click': (event) ->
		unless $(event.target).hasClass 'removePersonButton'
			FlowRouter.go 'personView', id: @_id

	'click .removePersonButton': ->
		alertModal(
			'Zeker weten?',
			TAPi18n.__ 'projectPersonRemovalMessage', @profile.firstName
			DialogButtons.OkCancel,
			{ main: 'Is de bedoeling', second: 'heh!?' },
			{ main: 'btn-danger' },
			main: =>
				Projects.update currentProject()._id, $pull: participants: @_id
				notify TAPi18n.__('projectPersonRemovedNotice', @profile.firstName), 'notice'
		)
