@ScholierenClasses     = new Mongo.Collection 'scholieren.com'
@WoordjesLerenClasses  = new Mongo.Collection 'woordjesleren'
@Analytics             = new Mongo.Collection 'analytics'

Meteor.users._transform = (u) ->
	u.hasRole = (roles) -> userIsInRole u._id, roles

	u.getNormalizedCourseInfo = ->
		courseInfo = u.profile.courseInfo ? getCourseInfo u._id
		year: courseInfo.year
		schoolVariant: normalizeSchoolVariant courseInfo.schoolVariant

	u
