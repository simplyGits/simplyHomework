###*
# Base exception that extends Error to provide more useful stuff.
#
# @class Exception
###
class @Exception extends Error
	constructor: (@message) ->
		super @message
		@date = new Date
		@stack = super.stack
###*
# Class to tell that something still has to be done.
#
# @class TodoException
###
class @TodoException extends @Exception
	###*
	# Constructor for TodoException.
	#
	# @method constructor
	# @param message {String} The message that describes the thing that has to be done.
	###
	constructor: (@message) -> super "#{@message}"

###*
# Exception to tell that a action isn't supported in the current context.
#
# @class NotSupportedException
###
class @NotSupportedException extends @Exception
	###*
	# Constructor for NotSupportedException.
	#
	# @method constructor
	# @param message {String} The message that describes why this action doesn't work.
	###
	constructor: (@message) -> super "#{@message}"

class @NotFoundException extends @Exception
	###*
	# Constructor for NotFoundException.
	#
	# @method constructor
	# @param message {String} The message that describes the reason of life?
	###
	constructor: (@message) -> super "#{@message}"

###*
# Exception to tell that the current action isn't supported on the current platform.
# Example: Running a server only method on a client.
#
# @class WrongPlatformException
###
class @WrongPlatformException extends @Exception
	###*
	# Constructor for WrongPlatformException
	#
	# @method constructor
	# @param message {String} The message that describes for what platform this action is made for.
	###
	constructor: (@message) -> super "#{@message}"

###*
# Exception to tell that an argument is not correct.
#
# @class ArgumentException
###
class @ArgumentException extends @Exception
	###*
	# Constructor for ArgumentException.
	#
	# @method constructor
	# @param argumentName {String} The name of the argument that is incorrect.
	# @param reason {String} The reason the given argument is incorrect.
	###
	constructor: (@argumentName, @reason) -> super "#{@argumentName} isn't valid, reason: #{@reason}"

class @NotAllowedException extends @Exception
	constructor: (@message) -> super "#{@message}"