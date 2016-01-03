currentPage = -> FlowRouter.getParam 'page'

items = [
	[ 'accountInfo', 'Account informatie' ]
	[ 'privacy', 'Privacyopties' ]
	[ 'externalServices', 'Verbonden sites' ]
	[ 'classes', 'Vakken' ]
	#[ 'notifications', 'Notificaties' ]
	[ 'about', 'Over simplyHomework' ]
].map ([ name, friendlyName ]) ->
	name: name
	friendlyName: friendlyName
	templateName: 'settings_page_' + name

Template.settings.helpers
	exists: ->
		page = currentPage()
		not page? or _.any items, name: page
	page: -> _.find items, (x) -> x.name is currentPage()

Template.settings.events
	'click #closeButton': -> history.back()

Template.settings.onRendered ->
	slide()
	setPageOptions
		title: 'Instellingen'
		color: null

	Meteor.defer ->
		if not currentPage()? and Session.equals 'deviceType', 'desktop'
			FlowRouter.withReplaceState ->
				FlowRouter.setParams page: items[0].name

Template['settings_sidebar'].helpers
	items: items

Template['settings_sidebar'].events
	'click #logout': -> App.logout()

Template['settings_sidebar_item'].helpers
	current: -> if currentPage() is @name then 'current' else ''
