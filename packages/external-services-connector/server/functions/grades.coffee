import { ExternalServicesConnector, getServices } from '../connector.coffee'
import { handleCollErr, hasChanged, markUserEvent, fetchConcurrently } from './util.coffee'
import { gradesInvalidationTime } from '../constants.coffee'

###*
# Updates the grades in the database for the given `userId` or the user
# in of current connection, unless the grades were updated shortly before.
#
# @method updateGrades
# @param userId {String}
# @param [forceUpdate=false] {Boolean} If true the grades will be forced to update, otherwise the grades will only be updated if they weren't updated in the last 20 minutes.
# @return {Error[]} An array containing errors from ExternalServices.
###
export updateGrades = (userId, forceUpdate = no) ->
	check userId, String
	check forceUpdate, Boolean

	user = Meteor.users.findOne userId
	gradeUpdateTime = user.events.gradeUpdate?.getTime()
	errors = []

	# return empty array when we don't have to update anything (using `errors`
	# so that we don't have to create a new array, micro-optimisations FTW).
	if not forceUpdate and
	gradeUpdateTime? and gradeUpdateTime > _.now() - gradesInvalidationTime
		return errors

	services = getServices userId, 'getGrades'
	markUserEvent userId, 'gradeUpdate' if services.length > 0
	results = fetchConcurrently services, 'getGrades', userId,
		from: null
		to: null
		onlyRecent: no
		onlyEnds: no

	for externalService in services
		{ result, error } = results[externalService.name]
		if error?
			ExternalServicesConnector.handleServiceError externalService.name, userId, error
			errors.push error
			continue

		grades = Grades.find(
			ownerId: userId
			fetchedBy: externalService.name
			externalId: $in: _.pluck result, 'externalId'
		).fetch()

		for grade in result ? []
			continue unless grade?
			Grade.schema.clean grade, removeEmptyStrings: no
			val = _.find grades,
				externalId: grade.externalId
				fetchedBy: grade.fetchedBy

			if val?
				if hasChanged val, grade, [ 'dateTestMade', 'previousValues' ]
					items = [ 'dateFilledIn', 'grade', 'gradeStr', 'weight' ]
					if not grade.isEnd and
					hasChanged _.pick(val, items), _.pick(grade, items)
						grade.previousValues =
							dateFilledIn: val.dateFilledIn
							grade: val.grade
							gradeStr: val.gradeStr
							weight: val.weight

					Grades.update val._id, { $set: grade }, { removeEmptyStrings: no }, handleCollErr
			else
				Grades.insert grade

	errors
