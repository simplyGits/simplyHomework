Template.sidebar.onCreated ->
	@subscribe 'classes'

Template.sidebar.helpers
	'classes': -> classes()

Template.sidebar.events
	'click .sidebarFooterSettingsIcon': -> FlowRouter.go 'settings'
	'click #addClassButton': -> showModal 'addClassModal'
	'click #sidebarButton': -> closeSidebar?()
