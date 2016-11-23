import { Services, ExternalServicesConnector, getServices } from '../connector.coffee'
import { handleCollErr, hasChanged, diffAndInsertFiles } from './util.coffee'

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
	MIN_NEW_MESSAGES_LIMIT = 5

	for folder in folders
		for service in services
			handleErr = (e) ->
				ExternalServicesConnector.handleServiceError service.name, userId, e
				errors.push e

			results = []
			try # fetch the messages asked for
				results.push(
					service.getMessages folder, offset, LIMIT, userId
				)
			catch e
				handleErr e
				continue

			if offset > 0 # fetch new messages at top, unless we are asked for them.
				try
					results.push(
						service.getMessages folder, 0, Math.min(MIN_NEW_MESSAGES_LIMIT, offset), userId
					)
				catch e
					handleErr e
					continue

			messages = _(results)
				.pluck 'messages'
				.flatten()
				.value()
			files = _(results)
				.pluck 'files'
				.flatten()
				.value()

			fileKeyChanges = diffAndInsertFiles userId, files

			for message in messages
				continue unless message?
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

export sendMessage = (subject, body, recipients, service, userId) ->
	check subject, String
	check body, String
	check recipients, [String]
	check service, String
	check userId, String

	body += AD_STRING

	service = _.find Services, (s) -> s.name is service and s.can userId, 'sendMessage'
	if not service?
		throw new Meteor.Error 'not-supported'

	service.sendMessage subject, body, recipients, userId

export replyMessage = (id, all, body, service, userId) ->
	check id, String
	check all, Boolean
	check body, String
	check service, String
	check userId, String

	message = Messages.findOne
		_id: id
		fetchedFor: @userId
	unless message?
		throw new Meteor.Error 'message-not-found'

	id = _(message.externalId).split('_').last()

	service = _.find Services, (s) -> s.name is service and s.can userId, 'getMessages'
	service.replyMessage id, all, body, userId
