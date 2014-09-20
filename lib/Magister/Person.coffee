convertType = (original, setter) ->
	if setter
		if _.isNumber original
			throw new Error "Invalid value: \"#{original}\"." unless _.contains [1, 3, 4, 8], original
			return original

		else
			switch original.toLowerCase()
				when "group" then 1
				when "teacher" then 3
				when "pupil" then 4
				when "project" then 8

				else throw new Error "Invalid value: \"#{original}\"."
	
	else
		switch original
			when 1 then "group"
			when 3 then "teacher"
			when 4 then "pupil"
			when 8 then "project"
			
			else undefined

class @Person
	constructor: (@_magisterObj, @_type, @_firstName, @_lastName) ->
		throw new Error "One or more arguments is not a string." if _.any _.toArray(arguments)[1..], (a) -> a? and not _.isString a

		@id = _getset "_id"
		@type = _getset "_type", ((val) => @_type = convertType(val, yes)), convertType
		@firstName = _getset "_firstName"
		@lastName = _getset "_lastName"
		@namePrefix = _getset "_namePrefix"
		@fullName = _getset "_fullName"
		@description = _getset "_description"
		@group = _getset "_group"
		@teacherCode = _getset "_teacherCode"
		@emailAddress = _getset "_emailAddress"

	_toMagisterStyle: ->
		obj = {}

		obj.Id = @_id
		obj.Type = @_type
		obj.Voornaam = @_firstName
		obj.Achternaam = @_lastName
		obj.Tussenvoegsel = @_namePrefix
		obj.Naam = @_fullName
		obj.Omschrijving = @_description
		obj.Groep = @_group
		obj.DocentCode = @_teacherCode
		obj.Emailadres = @_emailAddress

		return obj

	@_convertRaw = (magisterObj, raw) ->
		obj = new Person magisterObj, raw.Type, raw.Voornaam, raw.Achternaam

		obj._id = raw.Id
		obj._namePrefix = raw.Tussenvoegsel
		obj._fullName = raw.Naam
		obj._description = raw.Omschrijving ? raw.Naam
		obj._group = raw.Groep
		obj._teacherCode = raw.DocentCode
		obj._emailAddress = raw.Emailadres

		return obj