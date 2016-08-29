val = new ReactiveVar undefined

NoticeManager.provide 'noServices', ->
	has = val.get()

	unless has?
		Meteor.call 'getModuleInfo', (e, r) ->
			val.set _.any r, (m) -> m.loginNeeded and m.active
	else unless has
		header: 'Je hebt geen sites verbonden met simplyHomework'
		subheader: '''
		Zonder een verbonden site heeft simplyHomework weinig nut.
		Klik hier om met een site te verbinden.
		'''

		priority: 10

		onClick:
			action: 'route'
			route: 'settings'
			params:
				page: 'externalServices'
