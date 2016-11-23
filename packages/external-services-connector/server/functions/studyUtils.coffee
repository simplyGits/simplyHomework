import { ExternalServicesConnector, getServices } from '../connector.coffee'
import { handleCollErr, hasChanged, diffAndInsertFiles, markUserEvent } from './util.coffee'
import { studyutilsInvalidationTime } from '../constants.coffee'

###*
# Updates the studyUtils in the database for the given `userId` or the user
# in of current connection, unless the utils were updated shortly before.
#
# @method updateStudyUtils
# @param userId {String}
# @param [forceUpdate=false] {Boolean} If true the utils will be forced to update, otherwise the utils will only be updated if they weren't updated in the last 20 minutes.
# @return {Error[]} An array containing errors from ExternalServices.
###
export updateStudyUtils = (userId, forceUpdate = no) ->
	check userId, String
	check forceUpdate, Boolean
	UPDATE_CHECK_OMITTED = [
		'creationDate'
		'visibleFrom'
		'visibleTo'
		'updatedOn'
		'userIds'
		'classId'
	]

	user = Meteor.users.findOne userId
	studyUtilsUpdateTime = user.events.studyUtilsUpdate?.getTime()
	errors = []

	if not forceUpdate and
	studyUtilsUpdateTime? and
	studyUtilsUpdateTime > _.now() - studyutilsInvalidationTime
		return errors

	services = getServices userId, 'getStudyUtils'
	markUserEvent userId, 'studyUtilsUpdate' if services.length > 0

	for externalService in services
		result = null
		try
			result = externalService.getStudyUtils userId
		catch e
			ExternalServicesConnector.handleServiceError externalService.name, userId, e
			errors.push e
			continue

		studyUtils = StudyUtils.find({
			fetchedBy: externalService.name
			externalInfo: $in: _.pluck result.studyUtils, 'externalInfo'
		}, {
			transform: null
		}).fetch()

		fileKeyChanges = diffAndInsertFiles userId, result.files

		for studyUtil in result.studyUtils ? []
			val = _.find studyUtils,
				externalInfo: studyUtil.externalInfo
				classId: studyUtil.classId ? null

			studyUtil.fileIds = studyUtil.fileIds.map (id) -> fileKeyChanges[id] ? id

			if val?
				studyUtil.userIds = _(val.userIds)
					.concat studyUtil.userIds
					.uniq()
					.value()

				if hasChanged val, studyUtil, UPDATE_CHECK_OMITTED
					studyUtil.updatedOn = new Date()
					StudyUtils.update val._id, { $set: studyUtil }, handleCollErr
				else if studyUtil.userIds.length isnt val.userIds.length
					StudyUtils.update val._id, { $set: studyUtil }, handleCollErr
			else
				StudyUtils.insert studyUtil

	errors
