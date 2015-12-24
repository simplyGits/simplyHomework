Notices
===
`NoticesManager.provide` takes 2 arguments:
	- The name of the provider as string, has to be unique.
	- A function that takes no parameters, unless it's async, in that case it
	  takes 1 paramter: a callback.

```JavaScript
NoticesManager.provide('recentGrades', function () {
	let sub = Meteor.subscribe('externalCalendarItems', Date.today(), Date.today().addDays(4));
	// If you have nothing to display, return an fasely thing. We will handle
	// everything else for you.
	if (!hasData) return;
	return {
		template: 'infoNextLesson',
		data: nextAppointmentToday,

		header: 'Volgend Lesuur',
		subheader: nextAppointmentToday.description,
		priority: 4,

		onClick: {
			action: 'route',
			route: 'calendar',
			params: {
				time: +Date.today(),
			},
		},
		ready: () => { sub.ready() },
	};
});

// or async

NoticesManager.provide('recentGrades', function (cb) {
	// You can call `cb` as much as you want, and it will update the info.
	doSomeAsyncStuff(function (e, r) {
		cb({
			template: 'recentGrades',
			header: 'Recent behaalde cijfers',
			priority: 0,
			data: r,
			ready: () => { sub.ready() },
		});
	})
});
```
