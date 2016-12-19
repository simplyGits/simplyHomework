import { Services, ExternalServicesConnector, getServices } from '../connector.coffee'
import { handleCollErr, hasChanged, diffAndInsertFiles, fetchConcurrently } from './util.coffee'

AD_STRING = '\n\n---\nVerzonden vanuit <a href="http://www.simplyHomework.nl">simplyHomework</a>.'
###*
# @method updateMessages
# @param {String} userId
# @param {Number} offset
# @param {String[]} folders
# @param {Boolean} [forceUpdate=false]
# @return {Error[]}
###
export updateMessages = (userId, offset, folders, forceUpdate = no) ->
	check userId, String
	check offset, Number
	check folders, [String]
	check forceUpdate, Boolean

	services = getServices userId, 'getMessages'
	errors = []
	LIMIT = 20
	MAX_NEW_MESSAGES_LIMIT = 5

	folders.forEach (folder) ->
		results = fetchConcurrently(
			services
			'getMessages'
			userId
			folder
			offset
			LIMIT
		)
		if offset > 0
			topResults = fetchConcurrently(
				services
				'getMessages'
				userId
				folder
				0
				Math.min MAX_NEW_MESSAGES_LIMIT, offset
			)

		handleErr = (e) ->
			ExternalServicesConnector.handleServiceError service.name, userId, e
			errors.push e

		for service in services
			combined = []

			{ result, error } = results[service.name]
			unless error?
				combined.push result
			else
				handleErr error
				continue

			if offset > 0
				{ result, error } = topResults[service.name]
				unless error?
					combined.push result
				else
					handleErr error

			messages = _(combined)
				.pluck 'messages'
				.flatten()
				.compact()
				.value()

			files = _(combined)
				.pluck 'files'
				.flatten()
				.value()
			fileKeyChanges = diffAndInsertFiles userId, files

			for message in messages
				if message.body?
					message.body = message.body.replace AD_STRING, ''

				message.attachmentIds = message.attachmentIds.map (id) ->
					fileKeyChanges[id] ? id

				val = Messages.findOne
					fetchedFor: userId
					externalId: message.externalId
					fetchedBy: message.fetchedBy

				if val?
					###
					mergeUserIdsField = (fieldName) ->
						message[fieldName] = _(val[fieldName])
							.concat message[fieldName]
							.uniq()
							.value()
					###

					if hasChanged val, message, [ 'notifiedOn' ]
						Messages.update message._id, message, validate: no
				else
					Messages.insert message

	errors

export sendMessage = (userId, subject, body, recipients, service) ->
	check userId, String
	check subject, String
	check body, String
	check recipients, [String]
	check service, String

	body += AD_STRING

	service = _.find Services, (s) -> s.name is service and s.can userId, 'sendMessage'
	if not service?
		throw new Meteor.Error 'not-supported'

	service.sendMessage userId, subject, body, recipients

export replyMessage = (userId, id, all, body, service) ->
	check userId, String
	check id, String
	check all, Boolean
	check body, String
	check service, String

	message = Messages.findOne
		_id: id
		fetchedFor: @userId
	unless message?
		throw new Meteor.Error 'message-not-found'

	id = _(message.externalId).split('_').last()

	service = _.find Services, (s) -> s.name is service and s.can userId, 'getMessages'
	service.replyMessage userId, id, all, body
