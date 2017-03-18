{ Services } = require 'meteor/simply:external-services-connector'

NoticeManager.provide 'serviceUpdates', ->
	@subscribe 'serviceUpdates'

	ServiceUpdates.find({
		hidden: no
	}).map (u) ->
		service = _.find Services, name: u.fetchedBy
		body = Helpers.convertLinksToAnchor u.body.trim().replace /\r?\n/g, '<br>'

		id: u._id

		header: u.header
		subheader: "Mededeling via #{service.friendlyName}"

		template: 'serviceUpdateNotice'
		priority: u.priority - 10
		data: _.extend u, { body }

Template.serviceUpdateNotice.events
	'click button': ->
		setHidden = (val) => Meteor.call 'serviceUpdateSetHidden', @_id, val
		setHidden yes
		NotificationsManager.notify
			body: '<b>Mededeling verborgen</b>'
			html: yes

			buttons: [{
				label: 'ongedaan maken'
				callback: -> setHidden no
			}]
