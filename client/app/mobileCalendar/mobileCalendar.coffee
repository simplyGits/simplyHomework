currentDate = new ReactiveVar
@cachedAppointments = cachedAppointments = ReactiveVar {}

fetch = (date = currentDate().get()) =>
	return if cachedAppointments.get()["#{date.getTime()}"]?
	@magisterObj (m) -> m.ready -> @appointments date, no, (error, result) ->
		x = cachedAppointments.get()
		x["#{date.getTime()}"] = _.map result, ((appointment) -> _.extend appointment,
			__colorType: (
				if appointment.scrapped() then "scrapped"
				else switch appointment.infoType()
					when 1 then "homework"
					when 2, 3 then "quiz"
					when 4, 5 then "test"

					else ""
			)

			__classSchoolHour: appointment.beginBySchoolHour() ? ""
			__className: Helpers.cap(appointment.classes()[0] ? "")
			__classLocation: appointment.location() ? ""
		)
		cachedAppointments.set x

Template.mobileCalendar.helpers
	currentDate: -> DateToDutch currentDate.get()
	currentAppointments: -> cachedAppointments.get()["#{currentDate.get().getTime()}"]

currentBlazes = []
Template.mobileCalendar.rendered = =>
	currentDate.set beginDate = Router.current().data()

	$(".mobileCalendar").on "touchmove", (event) -> event.preventDefault()
	@calendar = new SwipeView ".mobileCalendar"
	calendar.onFlip ->
		Blaze.remove x for x in currentBlazes when x?
		currentDate.set beginDate.addDays calendar.pageIndex, yes

		for i in [0..2]
			currentBlazes.push Blaze.renderWithData Template.mobileCalendarPage, (->
				x = cachedAppointments.get()["#{currentDate.get().addDays((i - 1), yes).getTime()}"]
			), calendar.masterPages[i]

			fetch currentDate.get().addDays((i - 1), yes)