@externalServices = new SReactiveVar [Object]

Template.externalServices.helpers
	externalServices: -> _.filter externalServices.get(), 'loginNeeded'

Template.externalServices.events
	'click .externalServiceButton': (event) ->
		if @template?
			view = Blaze.renderWithData @template, this, document.body
			$("##{@templateName}")
				.modal()
				.on 'hidden.bs.modal', -> Blaze.remove view

Template.externalServiceResult.events
	'click .deleteButton': ->
		@setProfileData undefined
		Meteor.call 'deleteServiceData', @name

Template.externalServices.onRendered ->
	Meteor.call 'getModuleInfo', (e, r) ->
		services = _(r)
			.map (service) ->
				profileData = new SReactiveVar Match.Optional Object
				_.extend service,
					templateName: "#{service.name}InfoModal"
					template: Template["#{service.name}InfoModal"]

					setProfileData: (o) -> profileData.set o
					profileData: -> profileData.get()
			.each (service) ->
				if not service.loginNeeded
					# Create data for services that don't need to be logged into
					# (eg. Gravatar)
					Meteor.call 'createServiceData', service.name, (e, r) ->
						if e? then console.error e
						else service.setProfileData r
				else if service.hasData
					Meteor.call 'getServiceProfileData', service.name, (e, r) ->
						if e? then console.error e
						else service.setProfileData r
			.value()

		externalServices.set services
