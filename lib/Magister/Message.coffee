class @Message
	constructor: (@_magisterObj) ->
		unless @_magisterObj?
			throw new Error "Magister instance is null!"

		@_canSend = yes

		@id = 0
		@

	@_convertRaw: (magisterObj, raw) ->
		obj = new Message 