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
magisterObj = (userId) ->
	user = Meteor.users.findOne userId
	school = Schools.findOne user.profile.schoolId
	{ username, password } = user.magisterCredentials

	val = _cachedMagisterObjects[userId]?

	unless val? and val.invalidationTime < new Date().getTime()
		magister = new Magister school, username, password, null
		_cachedMagisterObjects[userId] =
			magister: magister
			invalidationTime: new Date().getTime() + 1200000

		return magister

	else return val.magister

Meteor.publish "magisterAppointments", (from, to) ->
	@unblock() # AWW YESSSS
	magister = magisterObj @userId

	pub = @
	magister.ready (err) ->
		unless err? then @appointments from, to, no, (e, r) ->
			for a in r then pub.added "magisterAppointments", a.id(), JSON.decycle a

	@ready()

Meteor.publish "magisterStudyGuides", ->
	@unblock()
	magister = magisterObj @userId

	pub = @
	magister.ready (err) ->
		unless err? then @studyGuides (e, r) ->
			left = r.length

			for studyGuide in r then do (studyGuide) ->
				studyGuide.parts (e, r) ->
					studyGuide.parts = r ? []
					pub.added "magisterStudyGuides", studyGuide.id(), JSON.decycle studyGuide

	@ready()

Meteor.publish "magisterAssignments", ->
	@unblock()
	magister = magisterObj @userId

	pub = @
	magister.ready (err) ->
		unless err? then @assignments no, yes, (e, r) ->
			for a in r then pub.added "magisterAssignments", a.id(), JSON.decycle a

	@ready()
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
