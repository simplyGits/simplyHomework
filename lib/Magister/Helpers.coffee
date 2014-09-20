class @_helpers
	###*
	# Adds a zero in front of the original number if it doesn't yet.
	#
	# @method addZero
	# @param original {Number} The number to add a zero in front to.
	# @return {String} The number as string with a zero in front of it.
	###
	@addZero: (original) -> return if original < 10 then "0#{original}" else original.toString()

@_getset = (varName, setter, getter) ->
	return (newVar) ->
		if newVar?
			if _.isFunction(setter) then setter(newVar, yes)
			else throw new Error "Changes on this property aren't allowed"
		return if _.isFunction(getter) then getter(@[varName], no) else @[varName]