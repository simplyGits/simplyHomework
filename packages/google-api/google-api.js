/* global gapi, GoogleApi, ReactiveVar, google */

// REVIEW: is it possible to use some promises instead of callbacks here?

const DEV_KEY = 'AIzaSyDZldjOJq0jrsi5IhtBIGz1ZHhbF3g-_ec'
const CLIENT_ID = '319072777142-apafv4ffhg4sv4thrertjtjk2q8eelke.apps.googleusercontent.com'

const loaded = new ReactiveVar(false)
let authInfo = undefined

const CB_NAME = '_google_cb'
window[CB_NAME] = function () {
	gapi.client.setApiKey(DEV_KEY)

	{
		let left = 0
		var genCallback = function () { // eslint-disable-line no-var
			left++
			return function () {
				if (--left == 0) {
					loaded.set(true)
				}
			}
		}
	}

	gapi.load('auth', { callback: genCallback() })
	gapi.load('picker', { callback: genCallback() })
	gapi.client.load('drive', 'v3').then(genCallback())
}
Meteor.startup(function () {
	const script = document.createElement('script')
	script.type = 'text/javascript'
	script.src = `https://apis.google.com/js/client.js?onload=${CB_NAME}`
	script.async = true
	document.body.appendChild(script)
})

GoogleApi = {}
GoogleApi.loaded = () => loaded.get()

GoogleApi.onLoaded = function (callback) {
	Tracker.autorun(function (c) {
		if (loaded.get()) {
			c.stop()
			callback()
		}
	})
}

GoogleApi.auth = function (callback) {
	GoogleApi.onLoaded(function () {
		if (authInfo != null && authInfo.error == null) {
			callback(authInfo.error, authInfo)
		} else {
			gapi.auth.authorize({
				'client_id': CLIENT_ID,
				'scope': 'https://www.googleapis.com/auth/drive.file',
				'immediate': false,
			}, function (res) {
				authInfo = res
				callback(authInfo.error, authInfo)
			})
		}
	})
}

GoogleApi.picker = function (oauthToken, callback) {
	const picker = new google.picker.PickerBuilder()
		.addView(() => {
			const view = new google.picker.DocsView()
			view.setIncludeFolders(true)
			view.setMode(google.picker.DocsViewMode.LIST)
			view.setOwnedByMe(true)
			return view
		})
		.addView(new google.picker.DocsUploadView())
		.setOAuthToken(oauthToken)
		.setDeveloperKey(DEV_KEY)
		.setCallback((data) => {
			if (data.action !== 'loaded') {
				callback(data)
			}
		})
		.setLocale('nl')
		.build()
	picker.setVisible(true)
	return picker
}
