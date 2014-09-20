@Schools         = new Meteor.Collection "schools"         , transform: (s) => @_decodeObject s
if Meteor.isClient # Fix for fast-render error
	@GoaledSchedules = new Meteor.Collection "goaledSchedules" , transform: (gs) => @_setDeps.goaledSchedule @_decodeObject gs
	@Classes         = new Meteor.Collection "classes"         , transform: (c) => @_setDeps.class @_decodeObject c
else
	@GoaledSchedules = new Meteor.Collection "goaledSchedules"
	@Classes         = new Meteor.Collection "classes"
#	@Schools         = new Meteor.Collection "schools"
		
@Schedules       = new Meteor.Collection "schedules"       , transform: (s) => @_setDeps.schedule @_decodeObject s
@Votes           = new Meteor.Collection "votes"           , transform: (v) => @_setDeps.vote @_decodeObject v
@Utils           = new Meteor.Collection "utils"           , transform: (u) => @_setDeps.util @_decodeObject u
@Tickets         = new Meteor.Collection "tickets"         , transform: (t) => @_setDeps.ticket @_decodeObject t
@Projects        = new Meteor.Collection "projects"        , transform: (p) => @_setDeps.project @_decodeObject p

@BetaPeople = new Meteor.Collection "betaPeople"