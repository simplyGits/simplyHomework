@ScholierenClasses     = new Meteor.Collection 'scholieren.com'
@WoordjesLerenClasses  = new Meteor.Collection 'woordjesleren'
@Analytics             = new Meteor.Collection 'analytics'

Meteor.users._transform = (u) ->
	u.hasRole = (roles) -> userIsInRole u._id, roles
	u.getNormalizedCourseInfo = ->
		courseInfo = getCourseInfo u._id
		year: courseInfo.year
		schoolVariant: normalizeSchoolVariant courseInfo.schoolVariant

	u
