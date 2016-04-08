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
		- `template`: `{String}` The name of the template to show in the notice.
		- `data`: `{any}` The data context for the template.
		- `header`: `{String}`
		- `subheader`: `{String}`
		- `priority`: `{Number}` The higher the priority the more the notice is shown in
		  front.
		- `onClick`: `{Object}` Object containing info about the action to take when the user clicks on it, also adds styling to the notice to indicate to the user that the notice is clickable.
			- `onClick.action`: `{String}` One of: 'route'
				- If this 'route':
					- `onClick.route`: `{String}`
					- `onClick.params`: `{Object}` *optional*
					- `onClick.queryParams`: `{Object}` *optional*

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
