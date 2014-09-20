@onGoogleLoad = ->
	gapi.load "auth", callback: onAuthLoad
	gapi.load "picker", callback: onPickerLoad
	gapi.client.load "drive", "v2", onDriveLoad

@onAuthLoad = ->
	gapi.auth.authorize {
		"client-id": "kaas"
		scope: "https://www.googleapis.com/auth/drive"
		immediate: no
	}, (authResult) =>
		if authResult? and !authResult.error?
			@googleOauthToken = authResult.access_token
			buildPicker()

buildPicker = ->
	return unless Session.get "pickerLoaded"

	@picker = new google.picker.PickerBuilder()
		.addView "google.picker.ViewId.DOCUMENTS"
		.addView "google.picker.ViewId.PRESENTATIONS"
		.addView "google.picker.ViewId.SPREADSHEETS"
		.addView "google.picker.ViewId.PDFS"
		.addView new google.picker.DocsUploadView()

@onPickerLoad = ->
	Session.set "pickerLoaded", yes
	buildPicker()

@onDriveLoad = -> return