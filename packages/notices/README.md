Notices
===
`NoticesManager.provide` takes 2 arguments:
	- The name of the provider as string, has to be unique.
	- A function that takes no parameters, unless it's async, in that case it
	  takes 1 parameter: a callback.

	  The function has bound to `this`:
	  	- `subscribe`: Same as `Meteor.subscribe`, should be used instead of
		  it to make sure that the loading indicator is shown.

	  The function should return any of:
	  	- A fasely value value when no data is currently avaiable.
		- An object containing:
			- template: The name of the template to show in the notice.
			- data: The data context for the template.
			- header
			- subheader
			- priority: The higher the priority the more the notice is shown in
			  front.
			- onClick: TODO

```JavaScript
NoticesManager.provide('recentGrades', function () {
	this.subscribe('externalCalendarItems', Date.today(), Date.today().addDays(4));
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
		});
	})
});
```
