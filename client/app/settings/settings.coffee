currentPage = -> FlowRouter.getParam 'page'

items = new ReactiveVar [
	[ 'accountInfo', 'Account informatie' ]
	[ 'privacy', 'Privacyopties' ]
	[ 'externalServices', 'Verbonden sites' ]
	[ 'classes', 'Vakken' ]
	[ 'logins', 'Logins' ]
	[ 'notifications', 'Notificaties' ]
	[ 'about', 'Over simplyHomework' ]
].map ([ name, friendlyName ]) ->
	name: name
	friendlyName: friendlyName
	templateName: 'settings_page_' + name

Template.settings.helpers
	exists: ->
		page = currentPage()
		not page? or _.any items.get(), name: page
	page: -> _.find items.get(), (x) -> x.name is currentPage()

Template.settings.events
	'click #closeButton': -> history.back()

Template.settings.onRendered ->
	setPageOptions
		title: 'Instellingen'
		color: null

	@autorun ->
		FlowRouter.watchPathChange()
		slide()

	@sequence = sequence = 'up up down down left right left right'
	field = 'settings.devSettings.enabled'
	@autorun (c) ->
		has = _.any items.get(), name: 'devSettings'

		if not has and getUserField Meteor.userId(), field
			Mousetrap.unbind sequence
			items.set [{
				name: 'devSettings'
				friendlyName: "🐊  instellingen"
				templateName: 'settings_page_devSettings'
			}].concat items.get()
			c.stop()
		else
			Mousetrap.bind sequence, ->
				Meteor.users.update Meteor.userId(),
					$set: "#{field}": yes

	Meteor.defer ->
		if not currentPage()? and Session.equals 'deviceType', 'desktop'
			FlowRouter.withReplaceState ->
				FlowRouter.setParams page: items.get()[0].name

Template.settings.onDestroyed ->
	Mousetrap.unbind @sequence

Template['settings_sidebar'].helpers
	items: -> items.get()

Template['settings_sidebar'].events
	'click #logout': -> App.logout()

Template['settings_sidebar_item'].helpers
	current: -> if currentPage() is @name then 'current' else ''
