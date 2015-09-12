String::trim ?= -> @replace /^\s+|\s+$/g, ''

Number.isInteger ?= (val) ->
	typeof val is 'number' and
	isFinite(val) and
	Math.floor(val) is val
