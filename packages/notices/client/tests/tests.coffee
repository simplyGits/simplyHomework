###*
# @method getTests
# @return {CalendarItem[]}
###
getTests = ->
	minuteTracker.depend()
	CalendarItems.find({
		'userIds': Meteor.userId()
		'content': $exists: yes
		'content.type': $in: [ 'test', 'exam', 'quiz', 'oral' ]
		'content.description': $exists: yes
		'startDate': $gt: new Date
		'scrapped': no
	}, {
		sort:
			startDate: 1
	}).fetch()

NoticeManager.provide 'tests', ->
	dateTracker.depend()
	@subscribe 'tests'

	if getTests().length > 0
		template: 'tests'
		header: 'Aankomende toetsen'
		priority: 1

Template.tests.helpers
	tests: -> getTests()

Template.testItem.helpers
	friendlyDate: ->
		dateTracker.depend()
		@relativeTime() or Helpers.formatDateRelative @startDate, no
	opacity: ->
		days = Helpers.daysRange new Date, @startDate, no
		days = Math.min days, 30
		(days / 2 + 1) ** -.2

Template.testItem.events
	'click': ->
		FlowRouter.go(
			'calendar'
			{ time: @startDate.date().getTime() }
			{ openCalendarItemId: @_id }
		)
