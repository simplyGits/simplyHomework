if Meteor.isClient # Fix for fast-render error
	@GoaledSchedules = new Meteor.Collection "goaledSchedules" , transform: (gs) => @_decodeObject gs
	@Classes         = new Meteor.Collection "classes"         , transform: (c) => @_decodeObject c
	@Schools         = new Meteor.Collection "schools"         , transform: (s) => @_decodeObject s
else
	@GoaledSchedules = new Meteor.Collection "goaledSchedules"
	@Classes         = new Meteor.Collection "classes"
	@Schools         = new Meteor.Collection "schools"
		
@Schedules       = new Meteor.Collection "schedules"       , transform: (s) => @_decodeObject s
@Votes           = new Meteor.Collection "votes"           , transform: (v) => @_decodeObject v
@Utils           = new Meteor.Collection "utils"           , transform: (u) => @_decodeObject u
@Tickets         = new Meteor.Collection "tickets"         , transform: (t) => @_decodeObject t
@Projects        = new Meteor.Collection "projects"        , transform: (p) => @_decodeObject p

@BetaPeople = new Meteor.Collection "betaPeople"