_.mixin
	###*
	# Returns the average of the values in the given array.
	#
	# @method mean
	# @param arr {Number[]} The array to get the average of.
	# @param [mapper] {Function} The function to map the values in the array to before counting it to the average.
	# @return {Number} The average of the given values.
	###
	mean: (arr, mapper) ->
		_.sum(arr, mapper) / arr.length
