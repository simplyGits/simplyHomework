###*
# File from a external service, such as Magister.
#
# @class ExternalFile
# @constructor
# @param name {String} The name of the file
###
class @ExternalFile
	constructor: (@name) ->
		###*
		# The MIME type of the file.
		# @property mime
		# @type String
		# @default null
		###
		@mime = null

		###*
		# The date of creation of the file.
		#
		# @property creationDate
		# @type Date
		# @default null
		###
		@creationDate = null

		###*
		# The size of the current file in bytes.
		# @property size
		# @type Number
		# @default null
		###
		@size = null

		###*
		# The info needed to download the current file.
		# @property downloadInfo
		# @type Object
		# @default null
		###
		@downloadInfo = null

	###*
	# Converts the given `file` to a ExternalFile.
	# @method fromMagister
	# @static
	# @param file {File} The Magister file to convert.
	# @return {ExternalFile} The given `file` converted to a ExternalFile.
	###
	@fromMagister: (file) ->
		externalFile = new ExternalFile file.name()

	###*
	# Converts the current ExternalFile to a File
	# @method toMagister
	# @return {File} The current file converted.
	###
	toMagister: ->
		obj = new File {}
