class @ExternalPerson
	constructor: (@firstName, @lastName) ->
		###*
		# @property type
		# @type String|undefined
		# @default undefined
		###
		@type = undefined

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
		# @type String|undefined
		# @default undefined
		###
		@emailAddress = undefined

		###*
		# @property teacherCode
		# @type String|undefined
		# @default undefined
		###
		@teacherCode = undefined

		###*
		# @property group
		# @type String|undefined
		# @default undefined
		###
		@group = undefined

		###*
		# The ID of this Person on the external service (eg Magister)
		# if it comes from one.
		#
		# @property externalId
		# @type mixed
		# @default undefined
		###
		@externalId = undefined

		###*
		# The name of the externalService that fetched this Person.
		# @property fetchedBy
		# @type String|undefined
		# @default undefined
		###
		@fetchedBy = undefined

		###*
		# If this person has a simplyHomework account this property will contain
		# theuserId of the person on simplyHomework as it appears in the
		# `Meteor.users` collection.
		#
		# @property userId
		# @type String
		# @default undefined
		###
		@userId = undefined

	toString: -> @fullName
