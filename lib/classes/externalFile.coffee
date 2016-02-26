###*
# File from a external service, such as Magister.
#
# @class ExternalFile
# @constructor
# @param name {String} The name of the file
###
class @ExternalFile
	constructor: (@name) ->
		@_id = new Mongo.ObjectID().toHexString()

		###*
		# @property userIds
		# @type String[]
		# @default []
		###
		@userIds = []

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
		# @property fetchedBy
		# @type String|undefined
		# @default undefined
		###
		@fetchedBy = undefined

		###*
		# @property externalId
		# @type mixed
		# @default undefined
		###
		@externalId = undefined

		###*
		# The info needed to download the current file.
		# @property downloadInfo
		# @type Object
		# @default null
		###
		@downloadInfo = null

	url: -> "/f/#{@_id}"
