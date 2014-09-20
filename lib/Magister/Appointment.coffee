class @Appointment
	constructor: (@_magisterObj) ->
		@id = _getset "_id"
		@begin = _getset "_begin"
		@end = _getset "_end"
		@beginBySchoolHour = _getset "_beginBySchoolHour"
		@endBySchoolHour = _getset "_endBySchoolHour"
		@fullDay = _getset "_fullDay"
		@description = _getset "_description"
		@location = _getset "_location"
		@status = _getset "_status"
		@type = _getset "_type"
		@displayType = _getset "_displayType"
		@content = _getset "_content"
		@infoType = _getset "_infoType"
		@notes = _getset "_notes"
		
		@isDone = _getset "_isDone", (d) =>
			# do put and change that shit blablabla old mata shit blablabla
			@_magisterObj.http.put @url(), @_toMagisterStyle(), {}, (->)

		@classes = _getset "_classes"
		@teachers = _getset "_teachers"
		@classRooms = _getset "_classRooms"
		@groups = _getset "_groups"
		@appointmentId = _getset "_appointmentId"
		@attachments = _getset "_attachments"
		@url = _getset "_url"

	_toMagisterStyle: ->
		obj = {}

		obj.Id = @_id
		obj.Start = @_begin
		obj.Einde = @_end
		obj.LesuurVan = @_beginBySchoolHour
		obj.LesuurTotMet = @_endBySchoolHour
		obj.DuurtHeleDag = @_fullDay
		obj.Omschrijving = @_description
		obj.Lokatie = @_location
		obj.Status = @_status
		obj.Type = @_type
		obj.WeergaveType = @_displayType
		obj.Inhoud = @_content
		obj.InfoType = @_infoType
		obj.Aantekening = @_notes
		obj.Afgerond = @_isDone
		obj.Lokalen = ( { Naam: c } for c in @_classRooms )
		obj.Docenten = ( p._toMagisterStyle() for p in @_teachers )
		obj.Vakken = []
		obj.Groepen = @_groups
		obj.OpdrachtId = @_appointmentId
		obj.Bijlagen = @_attachments

		return obj

	@_convertRaw: (magisterObj, raw) ->
		obj = new Appointment magisterObj

		obj._id = raw.Id
		obj._begin = new Date Date.parse raw.Start
		obj._end = new Date Date.parse raw.Einde
		obj._beginBySchoolHour = raw.LesuurVan
		obj._endBySchoolHour = raw.LesuurTotMet
		obj._fullDay = raw.DuurtHeleDag
		obj._description = raw.Omschrijving
		obj._location = raw.Lokatie
		obj._status = raw.Status
		obj._type = raw.Type
		obj._displayType = raw.WeergaveType
		obj._content = raw.Inhoud
		obj._infoType = raw.InfoType
		obj._notes = raw.Aantekening
		obj._isDone = raw.Afgerond
		obj._classes = (c.Naam for c in raw.Vakken)
		obj._teachers = (Person._convertRaw(obj, p) for p in raw.Docenten)
		obj._classRooms = (c.Naam for c in raw.Lokalen)
		obj._groups = raw.Groepen # ?
		obj._appointmentId = raw.OpdrachtId
		obj._attachments = raw.Bijlagen
		obj._url = "#{magisterObj._personUrl}/afspraken/1324953"

		return obj