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

	###*
	# Returns the median value of the given array
	#
	# @method median
	# @param {arr} {Number[]}
	# @return {Number}
	###
	median: (arr) ->
		sorted = _.sortBy arr
		middleIndex = (arr.length + 1) / 2

		if sorted.length % 2
			sorted[middleIndex - 1]
		else
			(sorted[middleIndex - 1.5] + sorted[middleIndex - 0.5]) / 2
