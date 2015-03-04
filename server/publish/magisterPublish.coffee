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
	user = Meteor.users.findOne userId
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
