sharedHours = new ReactiveVar undefined

Template.sharedHoursOverview.onCreated ->
	Meteor.call 'sharedHours', (e, r) ->
		sharedHours.set r ? []

Template.sharedHoursOverview.helpers
	loaded: -> sharedHours.get()?
	days: ->
		hours = _(sharedHours.get())
			.map (h) ->
				_.pull h.userIds, Meteor.userId()
				h.class = Classes.findOne h.classId
				h.users = Meteor.users.find(_id: $in: h.userIds).fetch()
				h
			.reject (h) -> h.userIds.length is 0
			.value()

		_(hours)
			.uniq (i) -> i.date.date().getTime()
			.sortBy (i) -> Helpers.daysRange new Date, i.date, no
			.map (i) ->
				m = moment i.date
				name: Helpers.cap Helpers.formatDateRelative i.date, no
				hours: (
					_(hours)
						.filter (x) -> m.isSame x.date, 'day'
						.sortBy 'date'
						.value()
				)
			.value()
