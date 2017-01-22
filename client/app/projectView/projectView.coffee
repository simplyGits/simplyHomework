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

defaultMime =
	fileTypeIconClass: "question-circle"
	fileTypeColor: "#001f3f"

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
	@autorun ->
		return unless GoogleApi.loaded()

		cached = Tracker.nonreactive -> cachedProjectFiles.get()
		fileIds = _.reject currentProject().driveFileIds, (s) -> cached[s]? or s in loading

		needed = fileIds.length
		pushFile = (r) ->
			cached[r.id] = r
			console.log r
			cachedProjectFiles.set cached if --needed is 0

		for driveFileId in fileIds
			loading.push driveFileId

			gapi.client.drive.files.get(
				fileId: driveFileId
			).execute (r) ->
				mimeInfo = _(fileTypes)
					.pairs()
					.find ([ mime, val ]) -> r.mimeType.indexOf(mime) is 0

				doc = _.extend r, mimeInfo[1] ? defaultMime
				doc.link = r.webViewLink
				pushFile doc
				_.pull loading, r.id

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
		project = this

		GoogleApi.auth (e, info) ->
			if e?
				notify 'Fout tijdens inloggen bij Google', 'error'
				return

			GoogleApi.picker info.access_token, (r) ->
				return unless r.action is 'picked'
				doc = r.docs[0]
				store = ->
					Projects.update project._id, {
						$addToSet: driveFileIds: doc.id
					}, (e) ->
						if e?
							notify 'Bestand kan niet worden toegevoegd', 'error'
							Kadira.trackError 'Client-add-file', e.message, stacks: e.stack
						else
							notify "#{doc.title} toegevoegd.", 'notice'

				setPermissions = ->
					if _.any(doc.permissions, (p) -> p.type is 'anyone' and p.role is 'writer')
						# Permissions are already good.
						store()
					else
						# Set correct permissions.
						gapi.client.drive.permissions.insert(
							fileId: doc.id
							resource:
								type: 'anyone'
								role: 'writer'
								withLink: yes
						).execute (r) ->
							if r.error?
								notify 'Bestand kan niet worden toegevoegd', 'error'
								Kadira.trackError 'Drive-client', r.error.message, stacks: EJSON.stringify r
							else
								store()

				if (doc.type isnt 'document' and 'openxmlformats' not in doc.mimeType) or
				_(fileTypes).keys().contains(doc.mimeType)
					# File is a Google document, no need to convert.
					setPermissions()
				else
					# File isn't a Google document, convert it to one.
					gapi.client.drive.files.copy(
						fileId: doc.id
						convert: yes
						resource:
							title: (
								val = doc.name.replace(/[-_]/g, ' ').split '.'
								if val.length is 1
									val[0]
								else
									_.initial(val).join '.'
							)
					).execute (res) ->
						if res.error?
							notify 'Bestand kan niet worden toegevoegd', 'error'
							Kadira.trackError 'Drive-client', res.error.message, stacks: EJSON.stringify res
						else
							doc = res
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
	# REVIEW: performance of this?
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
