@subs = new SubsManager

AccountController = RouteController.extend
	verifyMail: -> Accounts.verifyEmail @params.token, ->
		Router.go "app"
		notify "Email geverifiëerd", "success"

forceRemoveModal = ->
	$("body").removeClass "modal-open"
	$(".modal-backdrop").remove()

Router.configure
	onStop: forceRemoveModal
	trackPageView: true
	notFoundTemplate: "notFound"
	loadingTemplate: "loading"

Router.map ->
	@route "launchPage",
		fastRender: yes
		path: "/"
		layoutTemplate: "launchPage"
		onBeforeAction: ->
			Meteor.defer => @redirect "app" if Meteor.user()? or Meteor.loggingIn()
			@next()
		onAfterAction: ->
			document.title = "simplyHomework"
			$("meta[name='theme-color']").attr "content", "#32A8CE"

	@route "app",
		fastRender: yes
		subscriptions: ->
			NProgress?.start()
			return [
				Meteor.subscribe("classes")
				subs.subscribe("calendarItems")
				subs.subscribe("schools")
				subs.subscribe("projects")
			]

		onBeforeAction: ->
			Meteor.defer => @redirect "launchPage" unless Meteor.loggingIn() or Meteor.user()?
			@next()
		onAfterAction: ->
			Meteor.defer ->
				slide "overview"
				$("meta[name='theme-color']").attr "content", "#32A8CE"
			document.title = "simplyHomework | #{Meteor.user().profile.firstName} #{Meteor.user().profile.lastName}"

			App.followSetupPath() if @ready()

			NProgress?.done()

		layoutTemplate: "app"
		template: "appOverview"

	@route "classView",
		fastRender: yes
		layoutTemplate: "app"
		path: "/app/class/:classId"

		subscriptions: ->
			NProgress?.start()
			return [
				Meteor.subscribe("classes")
			]

		onBeforeAction: ->
			Meteor.defer => @redirect "launchPage" unless Meteor.loggingIn() or Meteor.user()?
			@next()
		onAfterAction: ->
			if !@data()? and @ready()
				@redirect "app"
				Meteor.defer -> slide "overview"
				swalert title: "Niet gevonden", text: "Jij hebt dit vak waarschijnlijk niet.", confirmButtonText: "o.", type: "error"
				return
			Meteor.defer =>
				slide @data()._id.toHexString(), yes
				$("meta[name='theme-color']").attr "content", @data().__color
			document.title = "simplyHomework | #{@data().name}"
			NProgress?.done()

		data: ->
			try
				id = new Meteor.Collection.ObjectID @params.classId
				return classes().smartFind id, (c) -> c._id
			catch e
				Meteor.call "log", "log", "Error while searching for the given class. #{e.message} | stack: #{e.stack}"
				return null

	@route "projectView",
		fastRender: yes
		layoutTemplate: "app"
		path: "/app/project/:projectId"

		subscriptions: ->
			NProgress?.start()
			return [
				subs.subscribe("usersData")
				Meteor.subscribe("classes")
				subs.subscribe("projects", new Meteor.Collection.ObjectID @params.projectId)
			]

		onBeforeAction: ->
			Meteor.defer => @redirect "launchPage" unless Meteor.loggingIn() or Meteor.user()?
			@next()
		onAfterAction: ->
			if !@data()? and @ready()
				@redirect "app"
				Meteor.defer -> slide "overview"
				swalert title: "Niet gevonden", text: "Dit project is niet gevonden.", type: "error"
				return

			Meteor.defer =>
				slide @data().__class._id.toHexString(), yes
				$("meta[name='theme-color']").attr "content", @data().__class.__color
			document.title = "simplyHomework | #{@data().name}"
			NProgress?.done()

		data: ->
			try
				id = new Meteor.Collection.ObjectID @params.projectId
				return projects().smartFind id, (p) -> p._id
			catch e
				Meteor.call "log", "log", "Error while searching for the given project. #{e.message} | stack: #{e.stack}"
				return null

	@route "calendar",
		fastRender: yes
		layoutTemplate: "app"
		path: "/app/calendar"

		subscriptions: ->
			NProgress?.start()
			return [
				subs.subscribe("usersData")
				Meteor.subscribe("classes")
				subs.subscribe("calendarItems")
			]

		onBeforeAction: ->
			Meteor.defer => @redirect "launchPage" unless Meteor.loggingIn() or Meteor.user()?
			@next()
		onAfterAction: ->
			Meteor.defer ->
				slide "calendar"
				$("meta[name='theme-color']").attr "content", "#32A8CE"
			document.title = "simplyHomework | Agenda"
			NProgress?.done()

	@route "mobileCalendar",
		fastRender: yes
		layoutTemplate: "app"
		path: "/app/mobileCalendar/:date?"

		subscriptions: ->
			NProgress?.start()
			return [
				subs.subscribe("usersData")
				Meteor.subscribe("classes")
				subs.subscribe("calendarItems")
			]

		onBeforeAction: ->
			Meteor.defer => @redirect "launchPage" unless Meteor.loggingIn() or Meteor.user()?
			@next()
		onAfterAction: ->
			Meteor.defer ->
				slide "calendar"
				$("meta[name='theme-color']").attr "content", "#32A8CE"
			document.title = "simplyHomework | Agenda"
			NProgress?.done()

		data: -> if params.date? then new Date(params.date).date() else Date.today()

	@route "personView",
		fastRender: yes
		layoutTemplate: "app"
		path: "/app/person/:_id"

		subscriptions: ->
			NProgress?.start()
			return [
				subs.subscribe("usersData")
				Meteor.subscribe("classes")
			]

		onBeforeAction: ->
			Meteor.defer => @redirect "launchPage" unless Meteor.loggingIn() or Meteor.user()?
			@next()
		onAfterAction: ->
			Meteor.defer -> slide "overview"
			if !@data()? and @ready()
				@redirect "app"
				swalert title: "Niet gevonden", text: "Dit persoon is niet gevonden.", type: "error"
				return

			document.title = "simplyHomework | #{@data().profile.firstName} #{@data().profile.lastName}"
			NProgress?.done()

		data: ->
			try
				return Meteor.users.findOne @params._id
			catch
				return null

	@route "press",
		fastRender: yes
		layoutTemplate: "press"
		onAfterAction: -> document.title = "simplyHomework | Pers"

	@route "verifyMail",
		fastRender: yes
		path: "/verify/:token"
		controller: AccountController
		action: "verifyMail"

	@route "forgotPass",
		fastRender: yes
		path: "/forgot"
		layoutTemplate: "forgotPass"

	@route "resetPass",
		fastRender: yes
		path: "/reset/:token"
		layoutTemplate: "resetPass"

	@route "full",
		fastRender: yes
		layoutTemplate: "full"