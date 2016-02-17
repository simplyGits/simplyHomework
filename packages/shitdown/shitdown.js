const things = [
	[ 'headers', /^######(.+)$/g, '<h6>$1</h6>' ],
	[ 'headers', /^#####(.+)$/g, '<h5>$1</h5>' ],
	[ 'headers', /^####(.+)$/g, '<h4>$1</h4>' ],
	[ 'headers', /^###(.+)$/g, '<h3>$1</h3>' ],
	[ 'headers', /^##(.+)$/g, '<h2>$1</h2>' ],
	[ 'headers', /^#(.+)$/g, '<h1>$1</h1>' ],
	[ 'strong', /([_*])\1(.*?)\1\1/g, '<strong>$2</strong>' ],
	[ 'em', /([_*])(.*?)\1/g, '<em>$2</em>' ],
	[ 'code', /`([^`]*)`/g, '<code>$1</code>' ],
]

shitdown = function (s, disabled = []) {
	check(s, String)
	check(disabled, [String])

	things.filter((pair) => {
		return disabled.indexOf(pair[0]) === -1
	}).forEach((pair) => {
		s = s.replace(pair[1], pair[2])
	})

	return s
}

shitdown.one = function (s, thing) {
	check(s, String)
	check(thing, String)
	const pair = things.find((pair) => pair[0] === thing)
	return s.replace(pair[1], pair[2])
}
