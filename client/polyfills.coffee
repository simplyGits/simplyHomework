unless _.isFunction(String::trim)
	String::trim = -> $.trim @