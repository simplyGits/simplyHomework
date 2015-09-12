class @ExternalPerson
	constructor: (@firstName, @lastName) ->
		###*
		# @property type
		# @type String|null
		# @default null
		###
		@type = null

		###*
		# @property fullName
		# @type String
		# @default firstName and lastName
		###
		@fullName = (
			if @firstName? and @lastName?
				"#{@firstName} #{@lastName}"
		)

		###*
		# @property namePrefix
		# @type String
		# @default ""
		###
		@namePrefix = ""

		###*
		# @property emailAddress
		# @type String|null
		# @default null
		###
		@emailAddress = null

		###*
		# @property teacherCode
		# @type String|null
		# @default null
		###
		@teacherCode = null

		###*
		# @property group
		# @type String|null
		# @default null
		###
		@group = null

		###*
		# The ID of this Person on the external service (eg Magister)
		# if it comes from one.
		#
		# @property externalId
		# @type mixed
		# @default null
		###
		@externalId = null

		###*
		# The name of the externalService that fetched this Person.
		# @property fetchedBy
		# @type String|null
		# @default null
		###
		@fetchedBy = null

	toString: -> @fullName
