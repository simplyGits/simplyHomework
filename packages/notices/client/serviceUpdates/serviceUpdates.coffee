{ Services } = require 'meteor/simply:external-services-connector'

NoticeManager.provide 'serviceUpdates', ->
	@subscribe 'serviceUpdates'

	ServiceUpdates.find({}).map (u) ->
		service = _.find Services, name: u.fetchedBy
		body = Helpers.convertLinksToAnchor u.body.trim().replace /\r?\n/g, '<br>'

		id: u._id

		header: u.header
		subheader: "Mededeling via #{service.friendlyName}"

		template: 'serviceUpdateNotice'
		priority: u.priority - 10
		data: _.extend u, { body }
