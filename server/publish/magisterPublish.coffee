request = Meteor.npmRequire "request"

###*
# Magister objects cached per userId.
# Key: userId, value: { invalidationTime: Number, magister: Magister }.
#
# @property _cachedMagisterObjects
# @type Object
# @default {}
###
_cachedMagisterObjects = {}

###*
# Gets (and invalidates) the Magister object
# for the given userId.
#
# @method magisterObj
# @param userId {String} The ID of the user to get the magisterObject for.
# @return {Magister} A Magister object for the given userId.
###
@magisterObj = (userId) ->
	user = Meteor.users.findOne userId, fields:
		magisterCredentials: 1
		profile: 1

	unless user? and user.magisterCredentials? and user.profile.schoolId?
		return undefined

	school = Schools.findOne user.profile.schoolId
	{ username, password } = user.magisterCredentials

	val = _cachedMagisterObjects[userId]

	if val? and val.invalidationTime > new Date().getTime()
		return val.magister
	else
		magister = new Magister school, username, password, null
		_cachedMagisterObjects[userId] =
			magister: magister
			invalidationTime: new Date().getTime() + 1200000

		return magister

# Magister Appointments from da server coast.
# Isn't currently used because it's too slow.
Meteor.publish "magisterAppointments", (from, to) ->
	@unblock() # AWW YESSSS
	user = Meteor.users.findOne @userId
	magister = magisterObj @userId
	unless magister?
		@ready()
		return

	pub = @
	magister.ready (err) ->
		if err? then pub.ready()
		else @appointments from, to, no, (e, r) ->
			for a in r
				a = JSON.decycle a

				delete a._magisterObj

				a.__id = "#{a._id}"
				a.__className = Helpers.cap(a.classes()[0]) if a.classes()[0]?

				a.__description = Helpers.convertLinksToAnchor a.content()
				a.__taskDescription = a.__description.replace /\n/g, "; "

				pub.added "magisterAppointments", a.id(), a

			pub.ready()

	return undefined

Meteor.publish "magisterStudyGuides", ->
	@unblock()
	magister = magisterObj @userId
	unless magister?
		@ready()
		return

	pub = @
	magister.ready (err) ->
		unless err? then @studyGuides (e, r) ->
			left = r.length

			for studyGuide in r then do (studyGuide) ->
				studyGuide.parts (e, r) ->
					studyGuide.parts = r ? []

					studyGuide = JSON.decycle studyGuide
					delete studyGuide._magisterObj

					for part in studyGuide.parts
						for file in part.files()
							downloadUrl = (
								if file._downloadUrl?
									"/magisterDownload/#{new Buffer(file._downloadUrl).toString "base64"}"
								else null
							)
							file.url = file.uri() ? downloadUrl

					pub.added "magisterStudyGuides", studyGuide.id(), studyGuide

	@ready()

Meteor.publish "magisterAssignments", ->
	@unblock()
	magister = magisterObj @userId
	unless magister?
		@ready()
		return

	pub = @
	magister.ready (err) ->
		if err? then pub.ready()
		else @assignments no, yes, (e, r) ->
			for a in r
				a = JSON.decycle a
				delete a._magisterObj
				pub.added "magisterAssignments", a.id(), a

			pub.ready()

	return undefined

Meteor.publish "magisterDigitalSchoolUtilties", (classDescription) ->
	@unblock()
	magister = magisterObj @userId
	unless magister?
		@ready()
		return

	pub = @
	magister.ready (err) ->
		if err? then pub.ready()
		#							 / == Say no to filling classes!
		#							 ||
		#							 \/
		else @digitalSchoolUtilities no, (e, r) ->
			if classDescription? then r = _.filter r, (du) -> du.class()?.description() is classDescription

			for du in r
				du = JSON.decycle du
				delete du._magisterObj
				pub.added "magisterDigitalSchoolUtilties", du.id(), du

			pub.ready()

	return undefined

Router.route "/magisterDownload/:url", (->
	url = new Buffer(@params.url, "base64").toString "utf8"

	token = @request.cookies["meteor_login_token"]
	hashedToken = Accounts._hashLoginToken(token) if token?
	userId = Meteor.users.findOne({
		"services.resume.loginTokens.hashedToken": hashedToken
	}, { fields: _id: 1 })?._id

	unless userId?
		@response.writeHead 403, "Content-Type": "text/plain"
		@response.end "No login token provided. BEN JE WEL INGELOGD?!\n"
		return

	magister = magisterObj userId

	request({
		method: "GET"
		url
		headers:
			cookie: magister.http._cookie
	}).pipe @response
), where: "server"
