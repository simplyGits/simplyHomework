const key = new ReactiveVar(undefined)

Template['2fa_key_modal'].helpers({
	key: () => key.get(),
})

Template['2fa_key_modal'].onRendered(function () {
	Meteor.call('tfa_getkey', function (e, r) {
		if (e == null) {
			let res = ''
			for (let i = 0; i < r.length; i++) {
				if (i > 0 && i % 4 === 0) {
					res += ' '
				}
				res += r[i]
			}
			key.set(res)
		}
	})
})
