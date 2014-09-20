@classes = ->
	tmp = []
	for tmpClass, i in _.sortBy(Classes.find(_id: { $in: (cI.id for cI in Meteor.user().classInfos) }).fetch(), (c) -> c.name())
		tmp.push _.extend tmpClass,
			__pos: ++i
			__largeName: tmpClass.name().length >= 8
			__taskAmount: Helpers.getTotal _.reject(GoaledSchedules.find(_homework: { $exists: true }, ownerId: Meteor.userId()).fetch(), (gS) -> !EJSON.equals(gS.classId(), tmpClass._id)), (gS) -> gS.tasksForToday().length
			__color: Meteor.user().classInfos.smartFind(tmpClass._id, (cI) -> cI.id).color
			__book: tmpClass.books().smartFind Meteor.user().classInfos.smartFind(tmpClass._id, (cI) -> cI.id).bookId, (b) -> b._id
	return tmp

@projects = ->
	tmp = []
	for tmpProject in Projects.find(_participants: Meteor.userId()).fetch()
		tmp.push _.extend tmpProject,
			__class: classes().smartFind tmpProject.classId(), (c) -> c._id
	return tmp

@kaas = ->
	unless Meteor.user()?
		alertModal "swag", "420 blze it\nKaas FTW"
	else
		alertModal "swag", "420 blze it\nKaas FTW\n\ndo u even lift #{Meteor.user().profile.firstName}?"
	return "420 blaze cheese"

@crash = ->
	speak "prepareer je anus"

	func = ->
		l = "a"
		while true
			console.log (l = l + "a")
	_.delay func, 1500

Meteor.startup ->
	if Session.get "isPhone"
		$(document).on "shown.bs.modal", "div.modal", -> return

		$(document).on "hidden.bs.modal", "div.modal", -> return

	window.viewportUnitsBuggyfill.init()

	NProgress.configure
		showSpinner: no

	if isOldInternetExplorer() # old Internet Explorer versions don't even support fast-render with iron-router :')
		$("body").text ""
		UI.insert UI.render(Template.oldBrowser), $("body").get()[0]
	else if "ActiveXObject" of window # Some css fixes for IE
		$("head").append "<style>.vCenter { position: relative !important } span#addProjectIcon { padding-right: 30px !important }</style>"
	
	# Some css fixes for Windows
	$("head").append '<style>.robotoThin, .btn-trans { font-weight: 300 !important } * { -webkit-font-smoothing: initial !important }</style>' if navigator.appVersion.indexOf("Win") isnt -1

	$.getScript "/js/advertisement.js" # adblock detection trick ;D

	if Session.get "isPhone" then Session.set "sidebarOpen", false
	else Session.set "sidebarOpen", true

	Deps.autorun -> try UserStatus.startMonitor idleOnBlur: true

	Deps.autorun -> if Meteor.user()? then ga "set", "&uid", Meteor.userId()

	ignoreMessages = [ "Server sent add for existing id"
		"Expected not to find a document already present for an add"
		"Script error."
	]
	window.onerror = (message, url, lineNumber) -> Meteor.call "log", "error", "Uncaught error at client: #{message} | #{url}:#{lineNumber}" unless _.some ignoreMessages, (m) -> Helpers.contains message, m