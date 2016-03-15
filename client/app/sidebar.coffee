Template.sidebar.onCreated ->
	@subscribe 'classes'

Template.sidebar.helpers
	'classes': -> classes()

Template.sidebar.events
	'click .sidebarFooterSettingsIcon': -> FlowRouter.go 'settings'
	'click #sidebarButton': -> closeSidebar?()
