Number.isInteger ?= (val) ->
	typeof val is 'number' and
	isFinite(val) and
	Math.floor(val) is val

Array::includes ?= (searchElem, fromIndex) ->
	self = Object this

	len = parseInt(self.length) or 0
	return no if len is 0

	n = parseInt(fromIndex) or 0
	k = (
		if n >= 0
			n
		else
			k = len + n
			k = 0 if k < 0
	)

	while k < len
		currentElement = self[k]
		if searchElem is currentElement or
		(isNaN(searchElem) and isNaN(currentElement))
			return true
		k++

	false
