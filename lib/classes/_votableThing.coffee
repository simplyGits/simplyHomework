root = @

@VoteType = 
	Downvote : -1
	None     :  0
	Upvote   :  1

class @VoteableThing
	constructor: ->
		@_className = "VoteableThing"

		@_votes = []
		@_votesDependency = new Deps.Dependency

		@votes = root.getset "_votes", [@Vote._match], no

	vote: (userId, voteType) ->
		if Meteor.isClient
			throw new WrongPlatformException "This method is serverside only"
		else
			if _.some(@_votes, (v) -> v.voterId is userId)
				@_votes = _.reject(@_votes, (v) -> v.voterId is userId).push new Vote @, userId, voteType
				@_votesDependency.changed()
			else
				@_votes.push new Vote @, userId, voteType
				@_votesDependency.changed()

	voteSum: ->
		sum = 0
		sum += vote.voteType() for vote in @votes()
		return sum

class @Vote
	constructor: (@voterId, @_voteType) ->
		@_className = "Vote"

		@voteType = root.getset "_voteType", Number
