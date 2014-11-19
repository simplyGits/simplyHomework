root = @

@VoteType =
	Downvote : -1
	None     :  0
	Upvote   :  1

class @VoteableThing
	constructor: (@_parent) ->
		@_className = "VoteableThing"
		@dependency = new Deps.Dependency

		@_votes = []
		@_votesDependency = new Deps.Dependency

		@votes = root.getset "_votes", [root.Vote._match], no

		Deps.autorun (computation) =>
			@_votersDependency.depend()
			@dependency.changed() if !computation.firstRun

	_setDeps: ->
		Deps.autorun (computation) => # Calls the dependency of the sender object, unless it's null
			@dependency.depend()
			@_parent.dependency.changed() if @_parent? and !computation.firstRun

	vote: (userId, voteType) ->
		if Meteor.isClient
			throw new WrongPlatformException "This method is serverside only"
		else
			if _.some(@_votes, (v) -> v.voterId is userId)
				@_votes = _.reject(@_votes, (v) -> v.voterId is userId).push new root.Vote @, userId, voteType
				@_votesDependency.changed()
			else
				@_votes.push new root.Vote @, userId, voteType
				@_votesDependency.changed()

	voteSum: -> Helpers.getTotal @votes(), (v) -> v.voteType()

class @Vote
	constructor: (@_parent, @voterId, @_voteType) ->
		@_className = "Vote"
		@dependency = new Deps.Dependency

		@voteType = root.getset "_voteType", Number

		Deps.autorun (computation) -> # Calls the dependency of the sender object, unless it's null
			@dependency.depend()
			@_parent.dependency.changed() if @_parent? and !computation.firstRun

	@_match: (vote) ->
		return Match.test vote, Match.ObjectIncluding
				voteId: String
				_voteType: Number