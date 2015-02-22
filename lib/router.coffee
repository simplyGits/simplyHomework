@subs = new SubsManager
	cacheLimit: 20
	expireIn: 10

AccountController = RouteController.extend
	verifyMail: -> Accounts.verifyEmail @params.token, ->
		@next()
		Router.go "app"
		notify "Email geverifiëerd", "success"

Router.configure
	onStop: ->
		$(".modal.in").modal "hide"
		$(".backdrop.dimmed").removeClass "dimmed"
		$(".tooltip").tooltip("destroy")
	trackPageView: true
	notFoundTemplate: "notFound"

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
				Meteor.subscribe("usersData")
			]

		onBeforeAction: ->
			unless Meteor.loggingIn() or Meteor.user()?
				@redirect "launchPage"
				return
			subs.subscribe("calendarItems")
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
				Meteor.subscribe("usersData")
			]

		onBeforeAction: ->
			unless Meteor.loggingIn() or Meteor.user()?
				@redirect "launchPage"
				return
			@next()
		onAfterAction: ->
			if !@data()? and @ready()
				@redirect "app"
				swalert title: "Niet gevonden", text: "Jij hebt dit vak waarschijnlijk niet.", confirmButtonText: "o.", type: "error"
				return

			Meteor.defer =>
				slide @data()._id.toHexString()
				$("meta[name='theme-color']").attr "content", @data().__color

			document.title = "simplyHomework | #{@data().name}"
			NProgress?.done()

		data: ->
			try
				id = new Meteor.Collection.ObjectID @params.classId
				return Classes.findOne id, transform: classTransform
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
				Meteor.subscribe("classes")
				Meteor.subscribe("usersData")
				subs.subscribe("projects", new Meteor.Collection.ObjectID @params.projectId)
			]

		onBeforeAction: ->
			unless Meteor.loggingIn() or Meteor.user()?
				@redirect "launchPage"
				return
			subs.subscribe("usersData", @data?()?.participants)
			@next()
		onAfterAction: ->
			if !@data()? and @ready()
				@redirect "app"
				swalert title: "Niet gevonden", text: "Dit project is niet gevonden.", type: "error"
				return

			if @data().__class? then Meteor.defer =>
				slide @data().__class._id.toHexString()
				$("meta[name='theme-color']").attr "content", @data().__class.__color

			document.title = "simplyHomework | #{@data().name}"
			NProgress?.done()

		data: ->
			try
				id = new Meteor.Collection.ObjectID @params.projectId
				return Projects.findOne id, transform: projectTransform
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
				Meteor.subscribe("classes")
				Meteor.subscribe("usersData")
				subs.subscribe("calendarItems")
			]

		onBeforeAction: ->
			unless Meteor.loggingIn() or Meteor.user()?
				@redirect "launchPage"
				return
			@redirect "mobileCalendar" if Session.get "isPhone"
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
		path: "/app/mobileCalendar"

		subscriptions: ->
			NProgress?.start()
			return [
				Meteor.subscribe("classes")
				Meteor.subscribe("usersData")
				subs.subscribe("calendarItems")
			]

		onBeforeAction: ->
			unless Meteor.loggingIn() or Meteor.user()?
				@redirect "launchPage"
				return
			@redirect "calendar" if (val = Session.get "isPhone")? and not val
			@next()
		onAfterAction: ->
			Meteor.defer ->
				slide "calendar"
				$("meta[name='theme-color']").attr "content", "#32A8CE"

			document.title = "simplyHomework | Agenda"
			NProgress?.done()

	@route "personView",
		fastRender: yes
		layoutTemplate: "app"
		path: "/app/person/:_id"

		subscriptions: ->
			NProgress?.start()
			return [
				subs.subscribe("usersData", [ @params._id ])
				Meteor.subscribe("classes")
				Meteor.subscribe("usersData")
			]

		onBeforeAction: ->
			unless Meteor.loggingIn() or Meteor.user()?
				@redirect "launchPage"
				return
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

	@route "privacy",
		fastRender: yes
		layoutTemplate: "privacy"
		onAfterAction: -> document.title = "simplyHomework | Privacy"

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
