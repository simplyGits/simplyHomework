hours = new ReactiveVar []

Meteor.setInterval (->
	Meteor.call 'getInbetweenHours', (e, r) ->
		hours.set r ? []
), ms.minutes 30

NoticeManager.provide 'inbetweenHour', ->
	current = _.find hours.get(), (h) -> h.start <= new Date() <= h.end
	hour = hours.get()[0]

	console.log hour, current
