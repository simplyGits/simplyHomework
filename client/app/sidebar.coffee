Template.sidebar.onCreated ->
	@autorun =>
		# We have to depend on the user's classInfos since the publishment isn't
		# reactive. This will make the publishment run again with the added classes.
		@subscribe 'classes' unless _.isEmpty getClassInfos()

Template.sidebar.helpers
	'classes': -> classes()

Template.sidebar.events
	'click .sidebarFooterSettingsIcon': -> FlowRouter.go 'settings'
	'click #addClassButton': -> showModal 'addClassModal'
