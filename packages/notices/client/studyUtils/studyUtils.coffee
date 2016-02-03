recentStudyUtils = ->
	dateTracker.depend()
	date = Date.today().addDays -4
	StudyUtils.find(
		updatedOn: $gte: date
	).fetch()

NoticeManager.provide 'studyUtils', ->
	@subscribe 'externalStudyUtils', onlyRecent: yes

	if recentStudyUtils().length
		template: 'recentStudyUtils'
		header: 'Recent gewijzigde vakinformtie'
		priority: 0

Template.recentStudyUtils.helpers
	groups: ->
		utils = recentStudyUtils()
		_(utils)
			.sortByOrder 'updatedOn', 'desc'
			.filter (x) -> x.classId?
			.uniq 'classId'
			.map (util) ->
				class: Classes.findOne util.classId
				utils: (
					_(utils)
						.filter (x) -> x.classId is util.classId
						.sortBy 'updatedOn'
						.pluck 'name'
						.join ' & '
				)
			.value()


Template.recentStudyUtilGroup.events
	'click': -> FlowRouter.go 'classView', id: @class._id
