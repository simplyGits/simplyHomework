Meteor.startup ->
	Deps.autorun -> if Meteor.user()? then Meteor.subscribe "essentials", -> loadMagisterInfo()