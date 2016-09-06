services = new Mongo.Collection 'services'

NoticeManager.provide 'noServices', ->
	@subscribe 'servicesInfo'

	infos = services.find().fetch()
	has = _.any infos, (s) -> s.loginNeeded and s.active

	unless has
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
