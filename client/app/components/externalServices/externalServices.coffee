# TODO: stop with this shitty global shared state stuff

SReactiveVar = require('meteor/simply:strict-reactive-var').default

@externalServices = new SReactiveVar [Object]

Template.externalServices.helpers
	externalServices: -> _.filter externalServices.get(), 'loginNeeded'

Template.externalServices.events
	'click .externalServiceButton': (event) ->
		ga 'send', 'event', 'externalServices', 'show modal'
		showModal @templateName, undefined, this if @template?

Template.externalServiceResult.events
	'click .deleteButton': ->
		ga 'send', 'event', 'externalServices', 'delete'
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
				setData = (e, r) ->
					service._loading.set no
					if e?
						console.error e
						service.setProfileData error: e
					else
						service.setProfileData r

				if not service.loginNeeded
					# Create data for services that don't need to be logged into
					# (eg. Gravatar)
					Meteor.call 'createServiceData', service.name, (e, r) ->
						setData e, r
				else if service.hasData
					Meteor.call 'getServiceProfileData', service.name, (e, r) ->
						setData e, r
				else service._loading.set no
			.value()

		externalServices.set services
