pickerLoaded = new ReactiveVar no
authLoaded = new ReactiveVar no
@driveLoaded = new ReactiveVar no
pickerResult = new ReactiveVar null

runningAuthLoop = no
oauthToken = null
@projectFilePicker = null

@onGoogleLoad = ->
	gapi.client.setApiKey "AIzaSyDZldjOJq0jrsi5IhtBIGz1ZHhbF3g-_ec"

	gapi.load("auth", callback: -> authLoaded.set yes)
	gapi.load("picker", callback: -> pickerLoaded.set yes)
	gapi.client.load("drive", "v2").then -> driveLoaded.set yes

###*
# Start Google auth flow and assign a callback to the picker result.
#
# @method onPickerResult
# @param cb {Function} The callback to give the result of the picker to.
# @return {Tracker.Computation} A computation which can be stopped.
###
@onPickerResult = (cb) ->
	projectFilePicker?.setVisible? yes

	return Tracker.autorun (c) ->
		if authLoaded.get() and not runningAuthLoop
			gapi.auth.authorize { # This succeeds if the user already has given us permission.
				"client_id": "319072777142-apafv4ffhg4sv4thrertjtjk2q8eelke.apps.googleusercontent.com"
				"scope": "https://www.googleapis.com/auth/drive"
				"immediate": yes
			}, (res) ->
				if !res? or res.error?
					gapi.auth.authorize { # If the user hasn't given us permission try again.
						"client_id": "319072777142-apafv4ffhg4sv4thrertjtjk2q8eelke.apps.googleusercontent.com"
						"scope": "https://www.googleapis.com/auth/drive"
						"immediate": no
					}, authResult

				else authResult arguments...

			runningAuthLoop = yes

		return unless pickerLoaded.get() and authLoaded.get() and driveLoaded.get() and pickerResult.get()?
		cb pickerResult.get()
		c.stop()
		pickerResult.set null

authResult = (res) ->
	if res? and !res.error?
		oauthToken = res.access_token
		buildPicker()

buildPicker = =>
	return unless pickerLoaded and oauthToken? and !projectFilePicker?

	NProgress.start()
	@projectFilePicker = new google.picker.PickerBuilder()
		.addView ( ->
			x = new google.picker.DocsView()
			x.setIncludeFolders yes
			x.setMode google.picker.DocsViewMode.LIST
			x.setOwnedByMe yes
			return x
		)()
		.addView new google.picker.DocsUploadView()
		.setOAuthToken oauthToken
		.setDeveloperKey "AIzaSyDZldjOJq0jrsi5IhtBIGz1ZHhbF3g-_ec"
		.setCallback (data) ->
			if data.action is "loaded" then NProgress.done()
			else pickerResult.set data
		.setLocale "nl"
		.build()
	@projectFilePicker.setVisible yes