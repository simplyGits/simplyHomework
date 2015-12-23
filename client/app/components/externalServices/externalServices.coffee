@externalServices = new SReactiveVar [Object]

Template.externalServices.helpers
	externalServices: -> _.filter externalServices.get(), 'loginNeeded'

Template.externalServices.events
	'click .externalServiceButton': (event) ->
		showModal @templateName, undefined, this if @template?

Template.externalServiceResult.events
	'click .deleteButton': ->
		@setProfileData undefined
		Meteor.call 'deleteServiceData', @name

Template.externalServices.onCreated ->
	externalServices.set []

	Meteor.call 'getModuleInfo', (e, r) ->
		services = _(r)
			.map (service) ->
				profileData = new SReactiveVar Match.Optional Object
				templateName = "#{service.name}InfoModal"
				_.extend service,
					templateName: templateName
					template: Template[templateName]

					setProfileData: (o) -> profileData.set o
					profileData: -> profileData.get()
					_loading: new SReactiveVar Boolean, yes
					ready: -> not @_loading.get()
			.each (service) ->
				if not service.loginNeeded
					# Create data for services that don't need to be logged into
					# (eg. Gravatar)
					Meteor.call 'createServiceData', service.name, (e, r) ->
						service._loading.set no
						if e? then console.error e
						else service.setProfileData r
				else if service.hasData
					Meteor.call 'getServiceProfileData', service.name, (e, r) ->
						service._loading.set no
						if e? then console.error e
						else service.setProfileData r
				else service._loading.set no
			.value()

		externalServices.set services
