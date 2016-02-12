Meteor.startup ->
	Tracker.autorun ->
		FlowRouter.watchPathChange()
		route = FlowRouter.current().route
		ga 'send',
			hitType: 'pageview'
			page: route.pathDef
			title: route.name

	Tracker.autorun ->
		ga 'set', 'userId', Meteor.userId() ? ''
